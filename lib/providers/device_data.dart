import 'dart:async';

import 'package:biometric_data_monitoring/providers/device_comm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../app_constant.dart';

/// DataSendResModel
/// - B7Pro와 송수신을 담당할 클래스
class DeviceSendRes extends DeviceCommon {
  final _bodyTemp = 0x24;
  final _heartRate = 0xE5;
  final _stepCount = 0XB1;
  final _btCmdStart = 0x01;
  final _hrCmdStart = 0x11;
  final _hrCmdStop = 0x00;
  // command send 대기 시간
  final _sendCmdMs = 1000;

  late final Function(List<int> data) notiyCallback;

  DeviceSendRes(String deviceID, this.notiyCallback) : super(deviceID);

  // B7Pro의 알림 채널 구독
  StreamSubscription<List<int>>? _dataSubscription;

  // 현재 작업 진행 상황 확인
  Future<void>? _curTask;

  // B7Pro Data Send Characteristic
  QualifiedCharacteristic get _getComandCharacteristic =>
      QualifiedCharacteristic(
        characteristicId: B7ProCommServiceCharacteristicUuid.command,
        serviceId: B7ProServiceUuid.comm,
        deviceId: deviceID,
      );

  // B7Pro Data Notiy Characteristic
  QualifiedCharacteristic get _getNotifyCharacteristic =>
      QualifiedCharacteristic(
        characteristicId: B7ProCommServiceCharacteristicUuid.rxNotify,
        serviceId: B7ProServiceUuid.comm,
        deviceId: deviceID,
      );

  void notiySubscription() {
    _dataSubscription =
        ble.subscribeToCharacteristic(_getNotifyCharacteristic).listen(
      (data) {
        debugPrint("Device ID : $deviceID ============================");
        debugPrint("data length : ${data.length}");
        debugPrint("data : $data");
        debugPrint("==================================================");
        if (_curTask != null) {
          notiyCallback(data);
        }
      },
      onDone: () {
        debugPrint("Device SubscribeToCharacteristic onDone");
        notiyCancle();
      },
      onError: (error) {
        debugPrint("Device SubscribeToCharacteristic onError : $error");
        notiyCancle();
      },
    );
  }

  void notiyCancle() {
    _dataSubscription?.cancel();
    _dataSubscription = null;
  }

  Future<void> run() async {
    debugPrint("B7Pro Start Task!");

    final complater = Completer<void>();

    if (_curTask != null) {
      await _curTask;
    }

    _curTask = _runTask();

    _curTask!.then((value) {
      complater.complete();
    });

    return complater.future;
  }

  Future<void> stop() async {
    debugPrint("B7Pro Stop Task!");
    final completer = Completer<void>();

    if (_curTask != null) {
      await _curTask;
      completer.complete();
    } else {
      completer.complete();
    }

    return completer.future;
  }

  Future<void> _runTask() async {
    try {
      var commnads = [
        [_bodyTemp, _btCmdStart],
        [_heartRate, _hrCmdStart],
        [_stepCount],
      ];

      var cleanCommands = [
        [_heartRate, _hrCmdStop]
      ];

      while (commnads.isNotEmpty) {
        await _sendCmd(commnads.first);
        commnads.removeAt(0);
        await Future.delayed(Duration(milliseconds: _sendCmdMs));
      }

      while (cleanCommands.isNotEmpty) {
        await _sendCmd(cleanCommands.first);
        cleanCommands.removeAt(0);
        await Future.delayed(Duration(milliseconds: _sendCmdMs));
      }

      _curTask = null;
    } catch (e) {
      debugPrint("Device Data RunTask Error :$e");
      notiyCancle();
      _curTask = null;
    }
  }

  Future<void> _sendCmd(List<int> value) async {
    final completer = Completer<void>();

    ble
        .writeCharacteristicWithResponse(_getComandCharacteristic, value: value)
        .then(
      (value) {
        completer.complete();
      },
    ).catchError(
      (onError) {
        debugPrint("onError! : $onError");
        completer.completeError(onError);
      },
    );

    return completer.future;
  }
}
