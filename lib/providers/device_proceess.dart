import 'dart:async';

import 'package:intl/intl.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/hive/chart_data.dart';
import '../models/hive/hive_model.dart';
import '../models/hive/user.dart';
import 'devce_data.dart';
import 'device_connection.dart';

enum DayType {
  day,
  month,
  year,
}

/// DeviceDataProcess
/// - 사용자별 B7Pro 디바이스 Data 관련 작업을 담당할 클래스
class DeviceDataProcess {
  late final User user;
  // Device Connection 작업 담당 클래스
  late DeviceConnection _connectionModel;
  // Device Data 처리 작업 작업 담당 클래스
  late DeviceData _dataModel;

  final _bioBox = Hive.box(BoxType.bio.boxName);
  final _statisticsBox = Hive.box(BoxType.statistics.boxName);

  double _lastTemp = 0.0;
  double _lastHeart = 0.0;
  double _lastStep = 0.0;
  DateTime _lastTimeStamp = DateTime.now();

  // 작업 타이머
  Timer? _taskTimer;
  // 현재 진행중인 작업 유무
  Future<void>? _curTask;

  final StreamController<ChartData> _chartStream = StreamController.broadcast();
  final StreamController<int> _batteryStream = StreamController.broadcast();

  DeviceDataProcess(this.user) {
    if (user.deviceID == null) {
      throw "User Device ID is null";
    }

    _dataModel = DeviceData(user.deviceID!, _notiyCallback);
    _connectionModel = DeviceConnection(user.deviceID!);
  }

  // Device Connection 상태
  Stream<DeviceConnectionState> get connectState =>
      _connectionModel.connectState;

  Stream<ChartData> get dataStream => _chartStream.stream;
  Stream<int> get batteryStream => _batteryStream.stream;

  bool db = false;

  void taksStart() async {
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
    await _connectionModel.disConnect();
    _taskTimer?.cancel();
    if (_curTask != null) {
      await _curTask;
    }

    return true;
  }

  void changeInterval(User user) async {
    taskStop();
    this.user = user;
    taksStart();
  }

  Future<void> _task() async {
    final completer = Completer<void>();

    var connCount = 5;
    var connFlag = false;
    for (int i = 0; i < connCount; i++) {
      connFlag = await _connectionModel.connect();
      if (connFlag) {
        break;
      }
    }

    if (!connFlag) {
      _curTask = null;
      completer.complete();
      return completer.future;
    }

    _dataModel.notiySubscription();
    _dataModel.run().then((value) async {
      int dataCount = 0;
      while (dataCount < 10) {
        if (_lastTemp > 0.0 && _lastTemp > 0.0 && _lastStep >= 0.0) {
          break;
        }

        await Future.delayed(const Duration(milliseconds: 500));
        dataCount++;
      }

      if (dataCount < 10) {
        _bioSave();
      }

      _dataModel.notiyCancle();
      await _connectionModel.disConnect();
      _curTask = null;
      completer.complete();
    });

    return completer.future;
  }

  void _bioSave() {
    var chartData = ChartData(
      _lastTemp,
      _lastHeart,
      _lastStep,
      _lastTimeStamp,
    );

    var boxdatas = _bioBox.get(user.key) ?? [];
    _bioBox.put(user.key, [...boxdatas, chartData]);

    _chartStream.add(chartData);

    for (var element in DayType.values) {
      _bioStSave(element);
    }
  }

  Future<void> _bioStSave(DayType dayType) async {
    String keyFormat(DayType type) {
      var key = _keyParsing(DateTime.now(), type);

      switch (type) {
        case DayType.day:
          return "${user.key}-Day-$key";
        case DayType.month:
          return "${user.key}-Month-$key";
        case DayType.year:
          return "${user.key}-Year-$key";
      }
    }

    var key = keyFormat(dayType);

    var beforeTemp = _statisticsBox.get("$key-temp");
    var beforeHeart = _statisticsBox.get("$key-heart");
    var beforeStep = _statisticsBox.get("$key-step");

    double lateTemp = _lastTemp;
    double lastHeart = _lastHeart;
    double lastStep = _lastStep;

    if (beforeTemp != null) {
      if (beforeHeart == null || beforeStep == null) {
        debugPrint("DB에 저장 된 데이터 에러 발생");
        throw Exception("DB ERROR");
      }
      lateTemp += beforeTemp;
      lastHeart += beforeHeart;
      lastStep += beforeStep;
    }

    await _statisticsBox.put("$key-temp", lateTemp);
    await _statisticsBox.put("$key-heart", lastHeart);
    await _statisticsBox.put("$key-step", lastStep);
  }

  String _keyParsing(DateTime time, DayType type) {
    switch (type) {
      case DayType.day:
        return DateFormat("yyyy.MM.dd").format(time);
      case DayType.month:
        return DateFormat("yyyy.MM").format(time);
      case DayType.year:
        return DateFormat("yyyy").format(time);
    }
  }

  void _notiyCallback(List<int> data) {
    var packet = Uint8List.fromList(data);

    if (packet.length == 2) {
      if (ByteData.sublistView(packet).getUint8(0) == 0xA2) {
        _batteryStream.add(data.last.toInt());
      }
    } else if (packet.length == 4) {
      _lastHeart = packet.last.toDouble();
    } else if (packet.length == 13) {
      _lastTemp = _parsingTempData(packet);
    } else if (packet.length == 18) {
      _lastStep = packet.last.toDouble();
    }

    _lastTimeStamp = DateTime.now();
  }

  double _parsingTempData(Uint8List packet) {
    if (packet.length == 13) {
      var convertUnit8 = Uint8List.fromList(packet);
      final ByteData byteData = ByteData.sublistView(convertUnit8);

      return byteData.getInt16(11) / 100.0;
    }

    return 0.0;
  }
}
