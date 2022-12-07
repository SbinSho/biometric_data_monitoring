import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../app_constant.dart';
import '../models/hive/permission_check.dart';

class DeviceScan {
  static final DeviceScan _singleton = DeviceScan._internal();

  factory DeviceScan() {
    return _singleton;
  }

  DeviceScan._internal();

  final _ble = FlutterReactiveBle();

  // key : device.mac, value : device object
  Map<String, DiscoveredDevice> deviceInfo = {};

  final _bleScaningStream = StreamController<bool>.broadcast();
  final _devicesStream =
      StreamController<Map<String, DiscoveredDevice>>.broadcast();

  StreamSubscription? _deviceScanSubscription;

  // 스캔 상태에 대한 스트림
  Stream<bool> get scanningState => _bleScaningStream.stream;

  // 디바이스 스캔 목록
  Stream<Map<String, DiscoveredDevice>> get deviceDatas =>
      _devicesStream.stream;

  void startScan([int scanningTime = 20]) async {
    await BlePermissionCheck.permissionCheck();

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
