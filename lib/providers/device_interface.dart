import 'dart:async';
import 'dart:typed_data';

import 'package:biometric_data_monitoring/providers/device_data.dart';
import 'package:biometric_data_monitoring/providers/device_scan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../models/user.dart';
import 'device_connection.dart';

class DeviceInterface {
  late final User _user;
  late final DeviceScanModel _scanModel;
  DataSendResModel? _dataModel;
  late final ConnectionProvider _connModel;

  final _heartStream = StreamController<double>.broadcast();
  final _tempStream = StreamController<double>.broadcast();
  final _stepStream = StreamController<double>.broadcast();
  final _timeStampStream = StreamController<DateTime>.broadcast();

  double? lastHeart;
  double? lastTemp;
  double? lateStep;
  DateTime? lastTimeStamp;

  Timer? taskTimer;

  DeviceInterface(this._user) {
    _scanModel = DeviceScanModel.instance;
    _connModel = ConnectionProvider(_user.userID);
  }

  String get userID => _user.userID;
  String? get deviceID => _user.deviceID;
  set deviceID(String? deviceID) => _user.deviceID = deviceID;

  Stream<double> get heartStream => _heartStream.stream;
  Stream<double> get tempStream => _tempStream.stream;
  Stream<double> get stepStream => _stepStream.stream;

  Stream<Map<String, DiscoveredDevice>> get deviceDatas =>
      _scanModel.deviceDatas;
  Stream<bool> get scanningState => _scanModel.scanningState;
  void startScan([int scanningTime = 10]) => _scanModel.startScan(scanningTime);
  void stopScan() => _scanModel.stopScan();

  Stream<DeviceConnectionState> get connectState => _connModel.connectState;

  ValueNotifier<Future<void>?> get taskRunningState =>
      _dataModel!.taskRunningState;

  void reStartTask() async {
    taskTimer?.cancel();

    await _dataModel!.stop();
    if (_dataModel!.taskRunningState.value == null) {
      startTask();
    }
  }

  void startTask() async {
    if (_user.deviceID == null) {
      throw Exception("Device ID is Null");
    }

    _dataModel = DataSendResModel(_user.deviceID!);
    _connModel.connect(_user.deviceID!);

    _connModel.connectState.listen((event) async {
      if (event == DeviceConnectionState.connected) {
        _dataModel!.notiySubscription(updateStream);
        // start data send
        await _dataModel!.run().then((value) => intervalComp());

        // start timer
        taskTimer = Timer.periodic(Duration(minutes: _user.interval), (timer) {
          _dataModel!.run().then((value) => intervalComp());
        });
      } else {
        debugPrint("연결 안됨!");
      }
    });
  }

  void stopTask() {
    _dataModel!.notiyCancle();
    _dataModel!.stop();
  }

  void intervalComp() {
    _heartStream.add(lastHeart ?? 0.0);
    _tempStream.add(lastTemp ?? 0.0);
    _stepStream.add(lateStep ?? 0.0);
    _timeStampStream.add(DateTime.now());
  }

  void updateStream(List<int> data) {
    if (data.length == 4) {
      // _heartStream.add(data.last.toDouble());
      lastHeart = data.last.toDouble();
    } else if (data.length == 13) {
      // _tempStream.add(_parsingTempData(data));
      lastHeart = _parsingTempData(data);
    } else if (data.length == 18) {
      lateStep = data.last.toDouble();
    }
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
