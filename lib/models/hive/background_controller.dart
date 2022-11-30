import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../providers/device_proceess.dart';

class BackgroundController {
  static void initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        buttons: [
          const NotificationButton(id: 'taskCancle', text: '수집 중단'),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        // 1분
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<bool> startForegroundTask() async {
    if (!await FlutterForegroundTask.canDrawOverlays) {
      final isGranted =
          await FlutterForegroundTask.openSystemAlertWindowSettings();
      if (!isGranted) {
        print('SYSTEM_ALERT_WINDOW permission denied!');
        return false;
      }
    }

    // You can save data using the saveData function.
    await FlutterForegroundTask.saveData(key: 'customData', value: 'hello');

    bool reqResult;
    if (await FlutterForegroundTask.isRunningService) {
      reqResult = await FlutterForegroundTask.restartService();
    } else {
      reqResult = await FlutterForegroundTask.startService(
        notificationTitle: 'Foreground Service is running',
        notificationText: 'Tap to return to the app',
        callback: startCallback,
      );
    }

    ReceivePort? receivePort;
    if (reqResult) {
      receivePort = await FlutterForegroundTask.receivePort;
    }

    return reqResult;
  }

  static Future<bool> stopForegroundTask() async {
    return await FlutterForegroundTask.stopService();
  }
}

@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(BackTaskHandler(null));
}

class BackTaskHandler extends TaskHandler {
  late final Map<String, DeviceDataProcess>? devices;

  SendPort? _sendPort;

  BackTaskHandler(this.devices);

  //
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;

    // You can use the getData function to get the stored data.
    final customData =
        await FlutterForegroundTask.getData<String>(key: 'customData');
    print('customData: $customData');
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    debugPrint("onEvent");
    /*  for (var element in devices.entries) {
      element.value.backTaskStart();
    } */
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    /*   for (var element in devices.entries) {
      element.value.taskStop();
    } */
    debugPrint("onDestroy");
    await FlutterForegroundTask.clearAllData();
  }

  // 수집 중단 버튼 클릭시, 데이터 수집 중단 및 앱 종료
  @override
  void onButtonPressed(String id) {
    debugPrint("onButtonPressed");
/*     for (var element in devices.entries) {
      element.value.taskStop();
    } */

    BackgroundController.stopForegroundTask();
  }

  // 알림창 클릭시 앱 실행
  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
    _sendPort?.send('onNotificationPressed');
  }
}
