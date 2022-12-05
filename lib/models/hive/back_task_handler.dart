import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../providers/device_proceess.dart';
import 'background_controller.dart';
import 'hive_model.dart';

class BackTaskHandler extends TaskHandler {
  Map<String, DeviceDataProcess>? devices;

  Future<void> init() async {
    await HiveModel.init();
    // devices = _loadDevices();
  }

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    debugPrint("Foreground onStart");
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    debugPrint("Foreground onEvent");
    // if (devices != null) {
    //   for (var element in devices!.entries) {
    //     var device = element.value;
    //     if (device.isRunning) {
    //       continue;
    //     }
    //     await device.backTaskStart();
    //   }
    // }
    sendPort?.send("onEvent");
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    debugPrint("Foreground onDestroy");
    // if (devices != null) {
    //   for (var device in devices!.entries) {
    //     await device.value.taskStop();
    //   }
    // }
    await FlutterForegroundTask.clearAllData();
  }

  // 수집 중단 버튼 클릭시, 데이터 수집 중단 및 앱 종료
  @override
  void onButtonPressed(String id) {
    debugPrint("Foreground onButtonPressed");
    // if (devices != null) {
    //   for (var device in devices!.entries) {
    //     device.value.taskStop();
    //   }
    // }
    BackgroundController.stopForegroundTask();
  }

  // 알림창 클릭시 앱 실행
  @override
  void onNotificationPressed() {
    debugPrint("Foreground onButtonPressed");
    // if (devices != null) {
    //   for (var device in devices!.entries) {
    //     device.value.taskStop();
    //   }
    // }
    FlutterForegroundTask.launchApp();
  }

  // Map<String, DeviceDataProcess> _loadDevices() {
  //   Map<String, User> loadUsers() {
  //     try {
  //       var userBox = Hive.box(BoxType.user.boxName);
  //       final values = userBox.values;

  //       final users = <String, User>{};

  //       for (var value in values) {
  //         if (value is User) {
  //           users[value.key] = value;
  //         }
  //       }

  //       return users;
  //     } catch (e) {
  //       debugPrint("Load User Error : $e");
  //       return {};
  //     }
  //   }

  //   var devices = <String, DeviceDataProcess>{};

  //   for (var user in loadUsers().entries) {
  //     if (user.value.deviceID != null) {
  //       var process = DeviceDataProcess(user.value);
  //       devices[user.key] = process;
  //     }
  //   }

  //   return devices;
  // }
}
