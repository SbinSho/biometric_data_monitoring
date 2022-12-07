import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../app_constant.dart';
import '../models/hive/permission_check.dart';
import 'device_common.dart';

/// DeviceConnectionModel
/// - 디바이스 연결을 담당할 클래스
class DeviceConnection extends DeviceCommon {
  DeviceConnection(String deviceID) : super(deviceID);

  // connection state stream
  final _connectionStream = StreamController<DeviceConnectionState>.broadcast();
  StreamSubscription<ConnectionStateUpdate>? _connectSubscription;
  Stream<DeviceConnectionState> get connectState => _connectionStream.stream;

  // device connection timer
  Timer? _connectionTimer;
  final _connectionTimeout = const Duration(seconds: 10);

  Future<bool> connect() async {
    var result = await BlePermissionCheck.permissionCheck();

    if (!result) {
      return false;
    }

    final completer = Completer<bool>();

    _connectionTimer = Timer(_connectionTimeout, () {
      debugPrint("Device Connection timeout.");
      disConnect().then((value) {
        completer.complete(false);
      });
    });

    _connectSubscription = ble.connectToDevice(
      id: deviceID,
      connectionTimeout: _connectionTimeout,
      servicesWithCharacteristicsToDiscover: {
        B7ProServiceUuid.comm: [
          B7ProCommServiceCharacteristicUuid.command,
          B7ProCommServiceCharacteristicUuid.rxNotify,
        ]
      },
    ).listen(
      (state) {
        if (state.connectionState == DeviceConnectionState.connected) {
          // Connection timeout timer cancle
          _connectionTimer?.cancel();
          _connectionTimer = null;
          if (completer.isCompleted == false) {
            completer.complete(true);
          }
        }

        _connectionStream.add(state.connectionState);
      },
      onDone: () {
        debugPrint("Device Connect onDone");
        _connectionTimer?.cancel();
        _connectionTimer = null;
        disConnect().then((value) {
          if (completer.isCompleted == false) {
            completer.complete(false);
          }
        });
      },
      onError: (error) {
        debugPrint("Device connectToDevice error: $error");
        _connectionTimer?.cancel();
        _connectionTimer = null;
        disConnect().then((value) {
          if (completer.isCompleted == false) {
            completer.complete(false);
          }
        });
      },
    );

    return completer.future;
  }

  Future<void> disConnect() async {
    debugPrint("B7Pro DisConnect!");

    _connectionTimer?.cancel();
    _connectionTimer = null;
    _connectionStream.add(DeviceConnectionState.disconnected);
    await _connectSubscription?.cancel();
    _connectSubscription = null;
  }
}
