import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/hive_model.dart';
import '../models/user.dart';

class BioMonitoringProvider extends ChangeNotifier {
  final Box _userBox = Hive.box(BoxType.user.boxName);

  BioMonitoringProvider();

  Set<User> loadUsers() {
    final values = _userBox.values;

    final users = <User>{};

    for (var value in values) {
      users.add(value);
    }

    return users;
  }

  bool idCheck(String id) {
    final overlapUser = _userBox.get(id.toLowerCase());

    if (overlapUser != null) {
      return false;
    }

    return true;
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

    //

    return true;
  }
}
