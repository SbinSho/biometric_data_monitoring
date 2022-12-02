import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FlutterForegroundPlugin {
  static const MethodChannel _mainChannel =
      MethodChannel('com.changjoopark.flutter_foreground_plugin/main');

  static const MethodChannel _callbackChannel =
      MethodChannel('com.changjoopark.flutter_foreground_plugin/callback');

  static Function? onStartedMethod;
  static Function? onStoppedMethod;

  /// [startForegroundService]
  ///
  static Future<void> startForegroundService({
    bool holdWakeLock = false,
    Function? onStarted,
    Function? onStopped,
    required String iconName,
    int color = 0,
    required String title,
    String content = "",
    String subtext = "",
    bool chronometer = false,
    bool stopAction = false,
    String? stopIcon,
    String stopText = 'Close',
  }) async {
    if (onStarted != null) {
      onStartedMethod = onStarted;
    }

    if (onStopped != null) {
      onStoppedMethod = onStopped;
    }

    await _mainChannel.invokeMethod("startForegroundService", <String, dynamic>{
      'holdWakeLock': holdWakeLock,
      'icon': iconName,
      'color': color,
      'title': title,
      'content': content,
      'subtext': subtext,
      'chronometer': chronometer,
      'stop_action': stopAction,
      'stop_icon': stopIcon,
      'stop_text': stopText,
    });
  }

  static Future<void> stopForegroundService() async {
    await _mainChannel.invokeMethod("stopForegroundService");
  }

  static Future<void> setServiceMethod(Function serviceMethod) async {
    final serviceMethodHandle =
        PluginUtilities.getCallbackHandle(serviceMethod)!.toRawHandle();

    _callbackChannel.setMethodCallHandler(_onForegroundServiceCallback);

    await _mainChannel.invokeMethod("setServiceMethodHandle",
        <String, dynamic>{'serviceMethodHandle': serviceMethodHandle});
  }

  static Future<void> setServiceMethodInterval({int seconds = 5}) async {
    await _mainChannel
        .invokeMethod("setServiceMethodInterval", <String, dynamic>{
      'seconds': seconds,
    });
  }

  static Future<void> _onForegroundServiceCallback(MethodCall call) async {
    switch (call.method) {
      case "onStarted":
        if (onStartedMethod != null) {
          onStartedMethod!();
        }
        break;
      case "onStopped":
        if (onStoppedMethod != null) {
          onStoppedMethod!();
        }
        break;
      case "onServiceMethodCallback":
        final CallbackHandle handle =
            CallbackHandle.fromRawHandle(call.arguments);
        PluginUtilities.getCallbackFromHandle(handle)!();
        break;
      default:
        break;
    }
  }
}

class AndroidForegroundService {
  static DateTime refreshedDateTime = DateTime.now();
  static Function _service = () => debugPrint("Service not set");

  static void startForegroundService(int minutes, Function service) async {
    _service = service;

    await FlutterForegroundPlugin.setServiceMethodInterval(seconds: 60);
    await FlutterForegroundPlugin.setServiceMethod(foregroundServiceMain);
    await FlutterForegroundPlugin.startForegroundService(
      holdWakeLock: false,
      onStarted: () {},
      onStopped: () {},
      title: "생체 모니터링",
      content: "실시간 생체 데이터 수집 중입니다",
      subtext: "수집 간격: 1분",
      iconName: "ic_launcher",
      stopText: "수집 중단",
      stopIcon: "ic_launcher",
      // This will not visible but mandatory
      stopAction: true,
    );
  }

  static void stopForegroundService() async {
    FlutterForegroundPlugin.stopForegroundService();
  }
}

// main function should be top level function
void foregroundServiceMain() async {
  AndroidForegroundService._service();
  AndroidForegroundService.refreshedDateTime = DateTime.now();
}

void restartForegroundService() async {
  FlutterForegroundPlugin.stopForegroundService();
  await FlutterForegroundPlugin.setServiceMethodInterval(seconds: 60);
  await FlutterForegroundPlugin.setServiceMethod(foregroundServiceMain);
  await FlutterForegroundPlugin.startForegroundService(
    holdWakeLock: false,
    onStarted: () {},
    onStopped: () {},
    title: "ThermoHub 체온 모니터링",
    content: "실시간 체온 수집 중입니다",
    subtext: "수집 간격: 1분",
    iconName: "th_notification_icon",
    stopText: "수집 중단",
    stopIcon: 'th_notification_icon',
    // This will not visible but mandatory
    stopAction: true,
  );
}
