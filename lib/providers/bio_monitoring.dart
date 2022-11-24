import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:hive/hive.dart';

import '../models/hive/hive_model.dart';
import '../models/hive/user.dart';

import 'device_proceess.dart';

class BioMonitoringProvider extends ChangeNotifier {
  late final List<User> users;
  late final Map<String, DeviceDataProcess> devices;

  final Box _userBox = Hive.box(BoxType.user.boxName);
  final Box _bioBox = Hive.box(BoxType.bio.boxName);

  BioMonitoringProvider() {
    users = _loadUsers();

    var devices = <String, DeviceDataProcess>{};
    for (var user in users) {
      if (user.deviceID != null) {
        var process = DeviceDataProcess(user);
        process.taksRun();
        devices[user.userID] = process;
      }
    }
    this.devices = devices;
  }

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

  Future<bool> editUser(String befreUserID, User user) async {
    if (_userBox.get(befreUserID) == null) {
      await _userBox.put(user.userID.toLowerCase(), user);
    } else {}

    return true;
  }

  Future<bool> registerDevice(User user, String deviceID) async {
    try {
      user.deviceID = deviceID;

      await _userBox.delete(user.userID.toLowerCase());
      await _userBox.put(user.userID.toLowerCase(), user);

      var process = DeviceDataProcess(user);
      devices[user.userID] = process;

      return true;
    } catch (e) {
      debugPrint("Device register fail : $e");
      return false;
    }
  }

  Future<bool> deleteDevice(User user) async {
    try {
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

  List<String> _loadDevices() {
    try {
      // final values = _deviceBox.values;

      final devices = <String>[];

      // for (var value in values) {
      //   devices.add(value);
      // }

      return devices;
    } catch (e) {
      debugPrint("Load Devices Error : $e");
      return [];
    }
  }
}
