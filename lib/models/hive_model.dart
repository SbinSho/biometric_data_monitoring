import 'package:hive_flutter/hive_flutter.dart';

import 'biometric.dart';
import 'user.dart';

enum BoxType {
  user,
  bio,
  statistics,
}

extension HiveBoxNameToString on BoxType {
  String get boxName {
    switch (this) {
      case BoxType.user:
        return "user";
      case BoxType.bio:
        return "bio";
      case BoxType.statistics:
        return "statistics";
    }
  }
}

class HiveTypeId {
  static const int userModel = 1;
  static const int biometricModel = 2;
}

/// hive model
/// box info
/// 1. BoxType.user
///     - key : user name (Primary Key, lowerCase)
///     - value : user model
/// 1. BoxType.bio
///     - key : user name (Primary Key)
///     - value : user bio data model
/// 1. BoxType.statistics
///     - key : user name (Primary Key)
///     - value : bio data statistics model
class HiveModel {
  static Future<void> init() async {
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(BiometricModelAdapter());

    await Hive.initFlutter();

    for (var element in BoxType.values) {
      await Hive.deleteBoxFromDisk(element.boxName);
      await Hive.openBox(element.boxName);
    }
  }
}
