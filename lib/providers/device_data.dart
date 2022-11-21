import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../app_constant.dart';

/// DataModel
/// - UI에서 사용 할 DataStream을 관리하는 객체
/// - 수집간격에 만큼 Stream 데이터를 전달하며, DB에도 저장
class DataSendResModel {
  late final String deviceID;

  DataSendResModel(this.deviceID);

  final _ble = FlutterReactiveBle();
  final _bodyTemp = 0x24;
  final _heartRate = 0xE5;
  final _stepCount = 0XB1;
  final _btCmdStart = 0x01;
  final _hrCmdStart = 0x11;
  final _hrCmdStop = 0x00;
  // command send 대기 시간
  final _sendCmdMs = 1000;

  // band data stream
  StreamSubscription<List<int>>? _dataSubscription;

  ValueNotifier<Future<void>?> taskRunningState =
      ValueNotifier<Future<void>?>(null);

  QualifiedCharacteristic get _getComandCharacteristic =>
      QualifiedCharacteristic(
        characteristicId: B7ProCommServiceCharacteristicUuid.command,
        serviceId: B7ProServiceUuid.comm,
        deviceId: deviceID,
      );

  QualifiedCharacteristic get _getNotifyCharacteristic =>
      QualifiedCharacteristic(
        characteristicId: B7ProCommServiceCharacteristicUuid.rxNotify,
        serviceId: B7ProServiceUuid.comm,
        deviceId: deviceID,
      );

  void notiySubscription(Function(List<int> data) callback) {
    _dataSubscription =
        _ble.subscribeToCharacteristic(_getNotifyCharacteristic).listen(
      (data) {
        debugPrint("data length : ${data.length}");
        debugPrint("data : $data");
        if (taskRunningState.value != null) {
          callback(data);
        }
      },
      onDone: () {
        debugPrint("Device SubscribeToCharacteristic onDone");
      },
      onError: (error) {
        debugPrint("Device SubscribeToCharacteristic onError : $error");
      },
    );
  }

  void notiyCancle() {
    _dataSubscription?.cancel();
    _dataSubscription = null;
  }

  Future<void> run() async {
    await stop();

    debugPrint("B7Pro Start Task!");
    taskRunningState.value = _runTask();
  }

  Future<void> stop() async {
    debugPrint("B7Pro Stop Task!");
    final completer = Completer<void>();

    if (taskRunningState.value != null) {
      taskRunningState.value!.then((value) {
        taskRunningState.value = null;
        completer.complete();
      });
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
    } catch (e) {
      debugPrint("Task Error :$e");
    }
  }

  Future<void> _sendCmd(List<int> value) async {
    final completer = Completer<void>();

    _ble
        .writeCharacteristicWithResponse(_getComandCharacteristic, value: value)
        .then(
          (value) => completer.complete(),
        )
        .catchError(
      (onError) {
        debugPrint("onError! : $onError");
      },
    );

    return completer.future;
  }
}
