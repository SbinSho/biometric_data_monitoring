import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/hive/chart_data.dart';
import '../models/hive/hive_model.dart';
import '../models/hive/user.dart';
import 'device_connection.dart';
import 'device_data.dart';

/// DeviceDataProcess
/// - 사용자별 B7Pro 디바이스 Data 관련 작업을 담당할 클래스
class DeviceDataProcess {
  late User user;
  final Box _bioBox = Hive.box(BoxType.bio.boxName);

  double _lastTemp = 0.0;
  double _lastHeart = 0.0;
  double _lastStep = 0.0;
  DateTime _lastTimeStamp = DateTime.now();

  final StreamController<ChartData> _chartStream = StreamController.broadcast();

  // 작업 타이머
  Timer? _taskTimer;
  // 현재 진행중인 작업 유무
  Future<void>? _curTask;

  // Device Connection 작업 담당 클래스
  DeviceConnection? _connectionModel;
  // Device Data 처리 작업 작업 담당 클래스
  DeviceSendRes? _dataModel;

  DeviceDataProcess(this.user) {
    if (user.deviceID == null) {
      throw "User Device ID is null";
    }

    _dataModel = DeviceSendRes(user.deviceID!, _notiyCallback);
    _connectionModel = DeviceConnection(user.deviceID!);
  }

  // Device Connection 상태
  Stream<DeviceConnectionState>? get connectState =>
      _connectionModel?.connectState;

  Stream<ChartData> get chartDataStream => _chartStream.stream;

  bool db = false;

  void taksRun() async {
    var duration = Duration(minutes: user.interval);
    _curTask = _task().then((value) {
      _taskTimer = Timer.periodic(duration, (timer) async {
        if (_curTask != null) {
          await _curTask;
        }
        _curTask = _task();
      });
    });
  }

  Future<bool> taskStop() async {
    _taskTimer?.cancel();
    if (_curTask != null) {
      await _curTask;
    }

    return true;
  }

  void taskRestart(User user) async {
    taskStop();
    this.user = user;
    taksRun();
  }

  Future<void> _task() async {
    final completer = Completer<void>();

    while (!await _connectionModel!.connect()) {}

    _dataModel!.notiySubscription();
    _dataModel!.run().then((value) async {
      int dataCount = 0;
      while (true) {
        if (dataCount > 10) {
          break;
        }
        if (_lastTemp > 0.0 && _lastHeart > 0.0 && _lastStep >= 0.0) {
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
        dataCount++;
      }

      if (dataCount < 10) {
        _bioSave();
      }

      _dataModel!.notiyCancle();
      await _connectionModel!.disConnect();

      _curTask = null;
      completer.complete();
    });

    return completer.future;
  }

  List? getBioDatas() => _bioBox.get(user.userID);

  void _bioSave() {
    var chartData = ChartData(
      _lastTemp,
      _lastHeart,
      _lastStep,
      _lastTimeStamp,
    );

    var boxdatas = _bioBox.get(user.userID) ?? [];
    _bioBox.put(user.userID, [...boxdatas, chartData]);

    _chartStream.add(chartData);
  }

  void _notiyCallback(List<int> data) {
    if (data.length == 4) {
      // _heartStream.add(data.last.toDouble());
      _lastHeart = data.last.toDouble();
    } else if (data.length == 13) {
      // _tempStream.add(_parsingTempData(data));
      _lastTemp = _parsingTempData(data);
    } else if (data.length == 18) {
      _lastStep = data.last.toDouble();
    }

    _lastTimeStamp = DateTime.now();
  }

  double _parsingTempData(List<int> tempData) {
    if (tempData.length == 13) {
      var convertUnit8 = Uint8List.fromList(tempData);
      final ByteData byteData = ByteData.sublistView(convertUnit8);

      return byteData.getInt16(11) / 100.0;
    }

    return 0.0;
  }
}
