import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../app_constant.dart';
import '../models/hive/chart_data.dart';
import '../models/hive/hive_model.dart';
import '../models/hive/user.dart';

/// DeviceDataProcess
/// - 사용자별 B7Pro 디바이스 Data 관련 작업을 담당할 클래스
class DeviceDataProcess {
  late final User user;
  // Device Connection 작업 담당 클래스
  late _DeviceConnection _connectionModel;
  // Device Data 처리 작업 작업 담당 클래스
  late _DeviceData _dataModel;

  final Box _bioBox = Hive.box(BoxType.bio.boxName);

  double _lastTemp = 0.0;
  double _lastHeart = 0.0;
  double _lastStep = 0.0;
  DateTime _lastTimeStamp = DateTime.now();

  // 작업 타이머
  Timer? _taskTimer;
  // 현재 진행중인 작업 유무
  Future<void>? _curTask;

  final StreamController<ChartData> _chartStream = StreamController.broadcast();
  final StreamController<int> _batteryStream = StreamController.broadcast();

  DeviceDataProcess(this.user) {
    if (user.deviceID == null) {
      throw "User Device ID is null";
    }

    _dataModel = _DeviceData(user.deviceID!, _notiyCallback);
    _connectionModel = _DeviceConnection(user.deviceID!);
  }

  // Device Connection 상태
  Stream<DeviceConnectionState> get connectState =>
      _connectionModel.connectState;

  Stream<ChartData> get dataStream => _chartStream.stream;
  Stream<int> get batteryStream => _batteryStream.stream;

  bool db = false;

  void taksStart() async {
    if (user.interval == 0) {
      _task();
      return;
    }

    var duration = Duration(minutes: user.interval);

    _curTask = _task().then((value) {
      _taskTimer = Timer.periodic(duration, (timer) async {
        if (_curTask != null) {
          await _curTask;
        }
        _curTask = _task();
      });
    });
  }

  Future<bool> taskStop() async {
    await _connectionModel.disConnect();
    _taskTimer?.cancel();
    if (_curTask != null) {
      await _curTask;
    }

    return true;
  }

  void taskRestart(User user) async {
    taskStop();
    this.user = user;
    taksStart();
  }

  Future<void> _task() async {
    final completer = Completer<void>();

    var connCount = 5;
    var connFlag = false;
    for (int i = 0; i < connCount; i++) {
      connFlag = await _connectionModel.connect();
      if (connFlag) {
        break;
      }
    }

    if (!connFlag) {
      _curTask = null;
      completer.complete();
      return completer.future;
    }

    _dataModel.notiySubscription();
    _dataModel.run().then((value) async {
      int dataCount = 0;
      while (dataCount < 10) {
        if (_lastTemp > 0.0 && _lastHeart > 0.0 && _lastStep >= 0.0) {
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
        dataCount++;
      }

      if (dataCount < 10) {
        _bioSave();
      }

      _dataModel.notiyCancle();
      await _connectionModel.disConnect();

      _curTask = null;
      completer.complete();
    });

    return completer.future;
  }

  void _bioSave([bool connFlag = false]) {
    var chartData = ChartData(
      0.0,
      0.0,
      0.0,
      DateTime.now(),
    );

    if (!connFlag) {
      chartData = ChartData(
        _lastTemp,
        _lastHeart,
        _lastStep,
        _lastTimeStamp,
      );
    }

    var boxdatas = _bioBox.get(user.key) ?? [];
    _bioBox.put(user.key, [...boxdatas, chartData]);

    _chartStream.add(chartData);
  }

  void _notiyCallback(List<int> data) {
    var packet = Uint8List.fromList(data);

    if (packet.length == 2) {
      if (ByteData.sublistView(packet).getUint8(0) == 0xA2) {
        _batteryStream.add(data.last.toInt());
      }
    } else if (packet.length == 4) {
      _lastHeart = packet.last.toDouble();
    } else if (packet.length == 13) {
      _lastTemp = _parsingTempData(packet);
    } else if (packet.length == 18) {
      _lastStep = packet.last.toDouble();
    }

    _lastTimeStamp = DateTime.now();
  }

  double _parsingTempData(Uint8List packet) {
    if (packet.length == 13) {
      var convertUnit8 = Uint8List.fromList(packet);
      final ByteData byteData = ByteData.sublistView(convertUnit8);

      return byteData.getInt16(11) / 100.0;
    }

    return 0.0;
  }
}

class _DeviceCommon {
  final ble = FlutterReactiveBle();
  late final String deviceID;

  _DeviceCommon(this.deviceID);
}

/// DeviceConnectionModel
/// - 디바이스 연결을 담당할 클래스
class _DeviceConnection extends _DeviceCommon {
  _DeviceConnection(String deviceID) : super(deviceID);

  // connection state stream
  final _connectionStream = StreamController<DeviceConnectionState>.broadcast();
  StreamSubscription<ConnectionStateUpdate>? _connectSubscription;
  Stream<DeviceConnectionState> get connectState => _connectionStream.stream;

  // device connection timer
  Timer? _connectionTimer;
  final _connectionTimeout = const Duration(seconds: 10);

  Future<bool> connect() async {
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

    _connectionStream.add(DeviceConnectionState.disconnected);
    await _connectSubscription?.cancel();
    _connectSubscription = null;
  }
}

/// DataSendResModel
/// - B7Pro와 송수신을 담당할 클래스
class _DeviceData extends _DeviceCommon {
  final _bodyTemp = 0x24;
  final _heartRate = 0xE5;
  final _stepCount = 0XB1;
  final _btCmdStart = 0x01;
  final _hrCmdStart = 0x11;
  final _hrCmdStop = 0x00;
  final _batteryInfo = 0xA2;

  // command send 대기 시간
  final _sendCmdMs = 1000;

  late final Function(List<int> data) notiyCallback;

  _DeviceData(String deviceID, this.notiyCallback) : super(deviceID);

  // B7Pro의 알림 채널 구독
  StreamSubscription<List<int>>? _dataSubscription;

  // 현재 작업 진행 상황 확인
  Future<void>? _curTask;

  // B7Pro Data Send Characteristic
  QualifiedCharacteristic get _getComandCharacteristic =>
      QualifiedCharacteristic(
        characteristicId: B7ProCommServiceCharacteristicUuid.command,
        serviceId: B7ProServiceUuid.comm,
        deviceId: deviceID,
      );

  // B7Pro Data Notiy Characteristic
  QualifiedCharacteristic get _getNotifyCharacteristic =>
      QualifiedCharacteristic(
        characteristicId: B7ProCommServiceCharacteristicUuid.rxNotify,
        serviceId: B7ProServiceUuid.comm,
        deviceId: deviceID,
      );

  void notiySubscription() {
    _dataSubscription =
        ble.subscribeToCharacteristic(_getNotifyCharacteristic).listen(
      (data) {
        debugPrint("Device ID : $deviceID =======================");
        debugPrint("data length : ${data.length}");
        debugPrint("data : $data");
        debugPrint("==================================================");
        if (_curTask != null) {
          notiyCallback(data);
        }
      },
      onDone: () {
        debugPrint("Device SubscribeToCharacteristic onDone");
        notiyCancle();
      },
      onError: (error) {
        debugPrint("Device SubscribeToCharacteristic onError : $error");
        notiyCancle();
      },
    );
  }

  void notiyCancle() {
    _dataSubscription?.cancel();
    _dataSubscription = null;
  }

  Future<void> run() async {
    debugPrint("B7Pro Start Task!");

    final complater = Completer<void>();

    if (_curTask != null) {
      await _curTask;
    }

    _curTask = _runTask();

    _curTask!.then((value) {
      complater.complete();
    });

    return complater.future;
  }

  Future<void> stop() async {
    debugPrint("B7Pro Stop Task!");
    final completer = Completer<void>();

    if (_curTask != null) {
      await _curTask;
      completer.complete();
    } else {
      completer.complete();
    }

    return completer.future;
  }

  Future<void> _runTask() async {
    try {
      var commnads = [
        [_batteryInfo],
        [_bodyTemp, _btCmdStart],
        [_heartRate, _hrCmdStart],
        [_stepCount],
      ];

      var cleanCommands = [
        [_heartRate, _hrCmdStop]
      ];

      while (commnads.isNotEmpty) {
        await _sendCmd(commnads.first);
        commnads.removeAt(0);
        await Future.delayed(Duration(milliseconds: _sendCmdMs));
      }

      while (cleanCommands.isNotEmpty) {
        await _sendCmd(cleanCommands.first);
        cleanCommands.removeAt(0);
        await Future.delayed(Duration(milliseconds: _sendCmdMs));
      }

      _curTask = null;
    } catch (e) {
      debugPrint("Device Data RunTask Error :$e");
      notiyCancle();
      _curTask = null;
    }
  }

  Future<void> _sendCmd(List<int> value) async {
    final completer = Completer<void>();

    ble
        .writeCharacteristicWithResponse(_getComandCharacteristic, value: value)
        .then(
      (value) {
        completer.complete();
      },
    ).catchError(
      (onError) {
        completer.completeError(onError);
      },
    );

    return completer.future;
  }
}
