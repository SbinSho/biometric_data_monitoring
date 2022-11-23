import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:hive/hive.dart';

import '../models/hive_model.dart';
import '../models/user.dart';
import 'device_connection.dart';
import 'device_data.dart';

class BioMonitoringProvider extends ChangeNotifier {
  late final List<User> users;
  Map<String, DeviceDataProcess> devices = {};

  final UserProcess _userProcess = UserProcess();

  BioMonitoringProvider() {
    users = _userProcess.loadUsers();
  }

  Future<bool> registerUser(User user) async {
    try {
      await _userProcess.registerUser(user);
      users.add(user);
      return true;
    } catch (e) {
      debugPrint("Register User Error : $e");
      return false;
    }
  }

  bool idCheck(String id) {
    try {
      return _userProcess.idCheck(id);
    } catch (e) {
      debugPrint("ID Check Error : $e");
      return false;
    }
  }

  Future<bool> registerDevice(User user, String deviceID) async {
    user.deviceID = deviceID;

    var process = DeviceDataProcess(user);
    devices[user.userID] = process;

    return true;
  }
}

/// UserProcess
/// - User와 관련 된 작업을 담당할 클래스
class UserProcess {
  static final UserProcess _singleton = UserProcess._internal();

  factory UserProcess() {
    return _singleton;
  }

  UserProcess._internal();

  final Box _userBox = Hive.box(BoxType.user.boxName);

  bool idCheck(String id) {
    final overlapUser = _userBox.get(id.toLowerCase());

    if (overlapUser != null) {
      return false;
    }

    return true;
  }

  List<User> loadUsers() {
    final values = _userBox.values;

    final users = <User>[];

    for (var value in values) {
      users.add(value);
    }

    return users;
  }

  Future<bool> registerUser(User user) async {
    if (!idCheck(user.userID)) {
      return false;
    }

    // save data
    await _userBox.put(user.userID.toLowerCase(), user);

    // debug msg
    debugPrint("User List==============");
    for (var element in _userBox.values) {
      debugPrint(element.toString());
    }
    debugPrint("=======================");

    return true;
  }

  Future<bool> editUser(User user) async {
    await _userBox.put(user.userID.toLowerCase(), user);

    return true;
  }
}

/// DeviceDataProcess
/// - B7Pro 디바이스 Data 관련 작업을 담당할 클래스
class DeviceDataProcess {
  late User user;

  DeviceDataProcess(this.user) {
    if (user.deviceID == null) {
      throw "User Device ID is null";
    }

    _dataModel = DeviceSendRes(user.deviceID!, _notiyCallback);
    _connectionModel = DeviceConnection(user.deviceID!);

    // TODO : DB에 저장 된 Data 초기화

    taksRun();
  }

  // Device Connection 작업 담당 클래스
  DeviceConnection? _connectionModel;
  // Device Data 처리 작업 작업 담당 클래스
  DeviceSendRes? _dataModel;

  // Device Connection 상태
  Stream<DeviceConnectionState>? get connectState =>
      _connectionModel?.connectState;

  // UI Chart에서 사용 할 Stream Data
  final StreamController<ChartData> _chartStream = StreamController.broadcast();
  Stream<ChartData> get chartDataStream => _chartStream.stream;

  // 작업 타이머
  Timer? _taskTimer;
  // 현재 진행중인 작업 유무
  Future<void>? _curTask;

  void taksRun() async {
    var duration = Duration(minutes: user.interval);

    await _task();

    _taskTimer = Timer.periodic(duration, (timer) => _curTask = _task());
  }

  Future<void> _task() async {
    while (!await _connectionModel!.connect()) {}

    _dataModel!.notiySubscription();
    _dataModel!.run().then((value) {
      _dataModel!.stop();
      _dataModel!.notiyCancle();
      _connectionModel!.disConnect();

      var chartData = ChartData(
        _lastHeart,
        _lastTemp,
        _lastStep,
        _lastTimeStamp,
      );

      // TODO : DB 데이터 저장 필요
      _chartStream.add(chartData);
    });
  }

  void taskStop() => _taskTimer?.cancel();

  void taskRestart(User user) async {
    _taskTimer?.cancel();
    await _curTask;
    this.user = user;
    taksRun();
  }

  double _lastHeart = 0.0;
  double _lastTemp = 0.0;
  double _lastStep = 0.0;
  DateTime _lastTimeStamp = DateTime.now();

  void _notiyCallback(List<int> data) {
    if (data.length == 4) {
      // _heartStream.add(data.last.toDouble());
      _lastHeart = data.last.toDouble();
    } else if (data.length == 13) {
      // _tempStream.add(_parsingTempData(data));
      _lastTemp = _parsingTempData(data);
    } else if (data.length == 18) {
      _lastStep = data.last.toDouble();
    }

    _lastTimeStamp = DateTime.now();
  }

  double _parsingTempData(List<int> tempData) {
    if (tempData.length == 13) {
      var convertUnit8 = Uint8List.fromList(tempData);
      final ByteData byteData = ByteData.sublistView(convertUnit8);

      return byteData.getInt16(11) / 100.0;
    }

    return 0.0;
  }
}

class ChartData {
  late final double heart;
  late final double temp;
  late final double step;
  late final DateTime timeStamp;

  ChartData(this.heart, this.temp, this.step, this.timeStamp);
}
