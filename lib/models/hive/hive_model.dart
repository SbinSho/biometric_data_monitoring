import 'package:biometric_data_monitoring/models/hive/chart_data.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'user.dart';

enum BoxType {
  user,
  device,
  bio,
  statistics,
}

extension HiveBoxNameToString on BoxType {
  String get boxName {
    switch (this) {
      case BoxType.user:
        return "user";
      case BoxType.device:
        return "device";
      case BoxType.bio:
        return "bio";
      case BoxType.statistics:
        return "statistics";
    }
  }
}

class HiveTypeId {
  static const int user = 1;
  static const int device = 2;
  static const int bio = 3;
  static const int statistics = 4;
}

/// hive model
/// box info
/// 1. BoxType.user
///     - key : user name (Primary Key, lowerCase)
///     - value : User Class
/// 1. BoxType.device
///     - key : user name (Primary Key, lowerCase)
///     - value : DeviceProcess Class
/// 1. BoxType.bio
///     - key : user name (Primary Key, lowerCase)
///     - value : data model
/// 1. BoxType.statistics
///     - key : user name (Primary Key)
///     - value : bio data statistics model
class HiveModel {
  static Future<void> init() async {
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(ChartDataAdapter());

    await Hive.initFlutter();

    await Hive.openBox(BoxType.user.boxName);
    await Hive.openBox(BoxType.bio.boxName);

    debugPrint("User Box =====================================");
    for (var element in Hive.box(BoxType.user.boxName).values) {
      debugPrint(element.toString());
    }
    debugPrint("==============================================");

    debugPrint("Chart Box ====================================");
    var chartBox = Hive.box(BoxType.bio.boxName);
    for (var key in chartBox.keys) {
      debugPrint("key : $key");
      for (var element in chartBox.get(key)!) {
        debugPrint(element.toString());
      }
    }
    debugPrint("==============================================");

    // for (var element in BoxType.values) {
    //   await Hive.deleteBoxFromDisk(element.boxName);
    //   await Hive.openBox(element.boxName);
    // }
  }
}
