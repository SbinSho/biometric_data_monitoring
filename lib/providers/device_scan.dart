import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../app_constant.dart';

class DeviceScanModel {
  static final DeviceScanModel _instance = DeviceScanModel._();
  static DeviceScanModel get instance => _instance;

  DeviceScanModel._();

  final _ble = FlutterReactiveBle();

  // key : device.mac, value : device object
  Map<String, DiscoveredDevice> deviceInfo = {};

  final _bleScaningStream = StreamController<bool>.broadcast();
  final _devicesStream =
      StreamController<Map<String, DiscoveredDevice>>.broadcast();
  StreamSubscription? _deviceScanSubscription;

  Stream<bool> get scanningState => _bleScaningStream.stream;
  Stream<Map<String, DiscoveredDevice>> get deviceDatas =>
      _devicesStream.stream;

  void startScan(int scanningTime) {
    deviceInfo.clear();
    _bleScaningStream.add(true);
    _deviceScanSubscription = _ble.scanForDevices(
      withServices: [
        B7ProAdvertisedServiceUuid.service1,
        B7ProAdvertisedServiceUuid.service2,
        B7ProAdvertisedServiceUuid.service3,
      ],
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      if (device.name != "") {
        if (!deviceInfo.containsKey(device.id)) {
          deviceInfo[device.id] = device;
          _devicesStream.add(deviceInfo);
          _bleScaningStream.add(true);
        }
      }
    }, onError: (error) {
      debugPrint("Scan Device Error : $error");
    });

    Timer(Duration(seconds: scanningTime), stopScan);
  }

  void stopScan() {
    _deviceScanSubscription?.cancel();
    _bleScaningStream.add(false);
  }
}
