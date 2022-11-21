import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../app_constant.dart';

class ConnectionProvider {
  late final String deviceID;

  ConnectionProvider(this.deviceID);

  final _ble = FlutterReactiveBle();

  // connection state stream
  final _connectionStream = StreamController<DeviceConnectionState>.broadcast();
  StreamSubscription<ConnectionStateUpdate>? _connectSubscription;
  Stream<DeviceConnectionState> get connectState => _connectionStream.stream;
  bool isConnected = false;

  // device connection timer
  Timer? _connectionTimer;
  final _connectionTimeout = const Duration(seconds: 10);

  Future<void> connect(String deviceID) async {
    _connectionTimer = Timer(_connectionTimeout, () {
      debugPrint("connection timeout.");
      _connectionStream.add(DeviceConnectionState.disconnected);

      disConnect();
    });

    _connectSubscription = _ble.connectToDevice(
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
          isConnected = true;
        }

        _connectionStream.add(state.connectionState);
      },
      onDone: () {
        debugPrint("Device Connect onDone");
        _connectionTimer?.cancel();
        _connectionTimer = null;
        disConnect();
      },
      onError: (error) {
        debugPrint("Device connectToDevice error: $error");
        _connectionTimer?.cancel();
        _connectionTimer = null;
        disConnect();
      },
    );
  }

  Future<void> disConnect() async {
    debugPrint("B7Pro DisConnect!");
    isConnected = false;
    await _connectSubscription?.cancel();
    _connectSubscription = null;
  }
}
