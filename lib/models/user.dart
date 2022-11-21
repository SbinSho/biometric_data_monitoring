import 'package:hive/hive.dart';

import 'hive_model.dart';

part 'user.g.dart';

@HiveType(typeId: HiveTypeId.userModel)
class User {
  @HiveField(0)
  // User ID
  late String userID;
  @HiveField(1)
  // ble device ID
  late String? deviceID;
  @HiveField(2)
  // device collection interval
  late int interval;
  @HiveField(3)
  // register timestamp or last edit timestamp
  late DateTime registerTime;

  User(this.userID, this.deviceID, this.interval, this.registerTime);

  @override
  String toString() =>
      "userID : $userID, deviceID : $deviceID, interval: $interval, registerTime : $registerTime";
}
