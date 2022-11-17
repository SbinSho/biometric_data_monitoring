import 'package:hive/hive.dart';

import 'hive_model.dart';

part 'user_data.g.dart';

@HiveType(typeId: HiveTypeId.userDataModel)
class UserDataModel {
  // user name
  @HiveField(0)
  late String userName;

  @HiveField(1)
  // ble device name
  late String? deviceName;

  @HiveField(2)
  // data collection interval
  late int dcInterval;

  UserDataModel(this.userName, [this.deviceName, this.dcInterval = 1]);

  @override
  String toString() {
    return "userName : $userName, deviceName : $deviceName, dcIntervale : $dcInterval";
  }
}
