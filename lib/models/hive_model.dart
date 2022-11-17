import 'package:hive_flutter/hive_flutter.dart';

import 'biometric.dart';
import 'user_data.dart';

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
  static const int userDataModel = 1;
  static const int biometricModel = 2;
}

/// hive model
/// box info
/// 1. BoxType.user
///     - key : user name (Primary Key)
///     - value : user data model
/// 1. BoxType.bio
///     - key : user name (Primary Key)
///     - value : user bio data model
/// 1. BoxType.statistics
///     - key : user name (Primary Key)
///     - value : bio data statistics model
class HiveModel {
  static Future<void> init() async {
    Hive.registerAdapter(UserDataModelAdapter());
    Hive.registerAdapter(BiometricModelAdapter());

    await Hive.initFlutter();

    for (var element in BoxType.values) {
      await Hive.openBox(element.boxName);
    }
  }
}
