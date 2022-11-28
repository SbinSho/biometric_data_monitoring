import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'package:hive/hive.dart';

import '../models/hive/chart_data.dart';
import '../models/hive/hive_model.dart';
import '../models/hive/user.dart';

import 'device_proceess.dart';
import 'device_scan.dart';

class BioMonitoringProvider extends ChangeNotifier {
  late final List<User> users;
  late final Map<String, DeviceDataProcess> devices;

  final Box _userBox = Hive.box(BoxType.user.boxName);
  final Box _bioBox = Hive.box(BoxType.bio.boxName);

  final DeviceScan _scanModel = DeviceScan();
  // 사용중인 디바이스 목록
  final Set<String> usedDevices = {};

  // 스캔 상태에 대한 스트림
  Stream<bool> get scanningState => _scanModel.scanningState;

  // 디바이스 스캔 목록
  Stream<Map<String, DiscoveredDevice>> get scanResults =>
      _scanModel.deviceDatas;

  // Device Connection 상태
  Stream<DeviceConnectionState>? connState(User user) =>
      devices[user.userID]?.connectState;

  Stream<ChartData>? chartDataStream(User user) =>
      devices[user.userID]?.dataStream;

  BioMonitoringProvider() {
    users = _loadUsers();
    devices = _loadDevices();
  }

  List<User> _loadUsers() {
    try {
      final values = _userBox.values;

      final users = <User>[];

      for (var value in values) {
        users.add(value);
      }

      return users;
    } catch (e) {
      debugPrint("Load User Error : $e");
      return [];
    }
  }

  Map<String, DeviceDataProcess> _loadDevices() {
    var devices = <String, DeviceDataProcess>{};

    for (var user in users) {
      if (user.deviceID != null) {
        var process = DeviceDataProcess(user);
        process.taksRun();
        devices[user.userID] = process;
        usedDevices.add(user.userID);
      }
    }

    return devices;
  }

  // 아이디 중복 체크
  bool idCheck(String id) {
    try {
      final overlapUser = _userBox.get(id.toLowerCase());

      if (overlapUser != null) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint("idCheck Error : $e");
      return false;
    }
  }

  // 사용자 등록
  Future<bool> registerUser(User user) async {
    try {
      if (!idCheck(user.userID)) {
        return false;
      }
      // save data
      await _userBox.put(user.userID.toLowerCase(), user);
      users.add(user);

      return true;
    } catch (e) {
      debugPrint("Register User Error : $e");
      return false;
    }
  }

  // 사용자 삭제
  Future<bool> deleteUser(User user) async {
    try {
      var key = user.userID.toLowerCase();

      if (user.deviceID != null) {
        await deleteDevice(user);
      }

      await _userBox.delete(key);
      await _bioBox.delete(key);

      users.remove(user);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Register User Error : $e");
      return false;
    }
  }

  // 사용자 수정
  Future<bool> editUser(String befreUserID, User user) async {
    if (_userBox.get(befreUserID) == null) {
      await _userBox.put(user.userID.toLowerCase(), user);
    } else {}

    return true;
  }

  // 사용자 디바이스 등록
  Future<bool> registerDevice(User user, String deviceID) async {
    try {
      user.deviceID = deviceID;
      usedDevices.add(deviceID);

      await _userBox.delete(user.userID.toLowerCase());
      await _userBox.put(user.userID.toLowerCase(), user);

      var process = DeviceDataProcess(user);
      process.taksRun();
      devices[user.userID] = process;

      return true;
    } catch (e) {
      debugPrint("Device register fail : $e");
      return false;
    }
  }

  // 사용자 디바이스 삭제
  Future<bool> deleteDevice(User user) async {
    try {
      usedDevices.remove(user.deviceID);
      user.deviceID = null;

      await _userBox.delete(user.userID.toLowerCase());
      await _userBox.put(user.userID.toLowerCase(), user);

      var process = devices[user.userID];
      await process!.taskStop();
      devices.remove(user.userID);

      return true;
    } catch (e) {
      debugPrint("Device register fail : $e");
      return false;
    }
  }

  void startScan() => _scanModel.startScan();
  void stopScan() => _scanModel.stopScan();

  List? getBioDatas(User user) => _bioBox.get(user.userID);
}
