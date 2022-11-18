import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/hive_model.dart';

class BioMonitoringProvider extends ChangeNotifier {
  final Box _userBox = Hive.box(BoxType.user.boxName);

  BioMonitoringProvider();

  Set<String> loadUsers() {
    final keys = _userBox.values;

    final users = <String>{};

    for (var key in keys) {
      users.add(key);
    }

    return users;
  }

  Future<bool> createUser(String userName) async {
    // get box
    final overlapUser = _userBox.get(userName.toLowerCase());

    if (overlapUser != null) {
      return false;
    }

    // save data
    await _userBox.put(userName.toLowerCase(), userName);

    // debug msg
    debugPrint("User List==============");
    for (var element in _userBox.values) {
      debugPrint(element.toString());
    }
    debugPrint("=======================");

    return true;
  }
}
