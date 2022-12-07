import 'dart:async';

import 'package:biometric_data_monitoring/models/hive/background_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'package:hive/hive.dart';

import '../models/hive/chart_data.dart';
import '../models/hive/hive_model.dart';
import '../models/hive/user.dart';

import 'device_proceess.dart';
import 'device_scan.dart';

class BioMonitoringProvider extends ChangeNotifier {
  late Map<String, User> users;
  late final Map<String, DeviceDataProcess> devices;

  final _userBox = Hive.box(BoxType.user.boxName);
  final _bioBox = Hive.box(BoxType.bio.boxName);
  final _statisticsBox = Hive.box(BoxType.statistics.boxName);

  final DeviceScan _scanModel = DeviceScan();
  // 사용중인 디바이스 목록
  final Set<String> usedDevices = {};

  // app lifecycle resumed
  ValueNotifier<DateTime> resumedTime = ValueNotifier<DateTime>(DateTime.now());

  // 스캔 상태에 대한 스트림
  Stream<bool> get scanningState => _scanModel.scanningState;

  // 디바이스 스캔 목록
  Stream<Map<String, DiscoveredDevice>> get scanResults =>
      _scanModel.deviceDatas;

  // Device Connection 상태
  Stream<DeviceConnectionState>? connState(User user) =>
      devices[user.key]?.connectState;

  Stream<ChartData>? chartDataStream(User user) =>
      devices[user.key]?.dataStream;

  Stream<int>? batteryStream(User user) => devices[user.key]?.batteryStream;

  BioMonitoringProvider() {
    users = _loadUsers();
    devices = _loadDevices();
  }

  Map<String, User> _loadUsers() {
    try {
      final values = _userBox.values;

      final users = <String, User>{};

      for (var value in values) {
        if (value is User) {
          users[value.key] = value;
        }
      }

      return users;
    } catch (e) {
      debugPrint("Load User Error : $e");
      return {};
    }
  }

  Map<String, DeviceDataProcess> _loadDevices() {
    var devices = <String, DeviceDataProcess>{};

    for (var user in users.entries) {
      if (user.value.deviceID != null) {
        var process = DeviceDataProcess(user.value);
        devices[user.key] = process;
        usedDevices.add(user.value.deviceID!);
        process.taskStart();
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
      await _userBox.put(user.key, user);
      users[user.key] = user;

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Register User Error : $e");
      return false;
    }
  }

  // 사용자 삭제
  Future<bool> deleteUser(User user) async {
    try {
      if (user.deviceID != null) {
        await deleteDevice(user);
      }

      await _userBox.delete(user.key);
      await _bioBox.delete(user.key);

      users.remove(user.key);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Register User Error : $e");
      return false;
    }
  }

  // 사용자 수정
  Future<bool> editUser(User beforeUser, User user) async {
    try {
      if (_userBox.get(beforeUser.key) == null) {
        await _userBox.put(user.key, user);
      } else {
        // Hive
        await _userBox.delete(beforeUser.key);
        await _userBox.put(user.key, user);
      }

      // Provider
      users.remove(beforeUser.key);
      users[user.key] = user;

      var process = devices[beforeUser.key];

      if (process != null) {
        await process.taskStop();

        devices.remove(beforeUser.key);
        var newProcess = DeviceDataProcess(user);
        devices[user.key] = newProcess;
        newProcess.changeInterval(user);
      }

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint("Register User Error : $e");
      return false;
    }
  }

  // 사용자 디바이스 등록
  Future<bool> registerDevice(User user, String deviceID) async {
    try {
      user.deviceID = deviceID;
      usedDevices.add(deviceID);

      await _userBox.delete(user.key);
      await _userBox.put(user.key, user);

      var process = DeviceDataProcess(user);
      process.taskStart();
      devices[user.key] = process;

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

      await _userBox.delete(user.key);
      await _userBox.put(user.key, user);

      var process = devices[user.key];
      await process!.taskStop();
      devices.remove(user.key);

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint("Device register fail : $e");
      return false;
    }
  }

  void startScan() => _scanModel.startScan();
  void stopScan() => _scanModel.stopScan();

  List? getStatics(User user) {
    return _bioBox.get(user.key);
  }

  Iterable<ChartData> getLastBioDatas(User user) {
    var values = _bioBox.get(user.key);
    var results = <ChartData>[];

    if (values == null) {
      return [];
    }

    var legnthCount = 30;
    for (var i = values.length - 1; i >= 0; i--) {
      if (legnthCount == 0) {
        break;
      }
      legnthCount--;
      results.add(values[i] as ChartData);
    }

    return results.reversed;
  }

  List<List<double>> getBioDatas(
    User user,
    DayType dayType,
    DateTime joinDate,
  ) {
    List<String> joinKey(DayType type) {
      var keys = <String>[];

      var joinYear = joinDate.year.toString();
      var joinMonth = joinDate.month.toString().padLeft(2, "0");
      switch (type) {
        case DayType.day:
          var lastDay =
              DateTime(joinDate.year, joinDate.month + 1, 0, 0, 0).day;

          for (int i = 1; i <= lastDay; i++) {
            keys.add(
                "${user.key}-Day-$joinYear.$joinMonth.${i.toString().padLeft(2, "0")}");
          }
          break;
        case DayType.month:
          for (int i = 1; i <= 12; i++) {
            keys.add(
                "${user.key}-Month-$joinYear.${i.toString().padLeft(2, '0')}");
          }
          break;
        // return "${user.key}-Month-$key";
        case DayType.year:
          for (int i = 0; i < 3; i++) {
            keys.add("${user.key}-Year-${joinDate.year - i}");
          }
          break;
      }

      return keys;
    }

    var results = <List<double>>[];

    for (var key in joinKey(dayType)) {
      var count = _statisticsBox.get("$key-count");
      var tempData = _statisticsBox.get("$key-temp");
      var heartData = _statisticsBox.get("$key-heart");
      var stepData = _statisticsBox.get("$key-step");

      results.add([count ?? 0, tempData ?? 0, heartData ?? 0, stepData ?? 0]);
    }

    return results;
  }

  void onDidChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint("AppLifecycleState : $state");

    switch (state) {
      case AppLifecycleState.resumed:
        resumedTime.value = DateTime.now();
        BackgroundController.stopForegroundTask();

        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        BackgroundController.startForegroundTask();

        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() async {
    debugPrint("Bio Monitoring Dispose!");
    super.dispose();
    for (var element in devices.entries) {
      await element.value.taskStop();
    }
  }
}

extension ConnectionStateName on DeviceConnectionState {
  String get getName {
    switch (this) {
      case DeviceConnectionState.connecting:
        return "연결중";
      case DeviceConnectionState.connected:
        return "연결됨";
      case DeviceConnectionState.disconnecting:
        return "연결해제중";
      case DeviceConnectionState.disconnected:
        return "연결해제됨";
    }
  }
}
