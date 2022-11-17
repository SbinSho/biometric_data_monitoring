import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/hive_model.dart';
import '../models/user_data.dart';

class BioMonitoringProvider extends ChangeNotifier {
  // key : user name, value : data model
  final userList = <String, UserDataModel>{};
  final Box _userBox = Hive.box(BoxType.user.boxName);

  BioMonitoringProvider() {
    _loadUserDatas();
  }

  // 최초 앱 실행시 한번만 동작 수행
  bool _loadUserDatas() {
    final keys = _userBox.keys;

    for (var element in keys) {
      final value = _userBox.get(element);
      if (value == null) {
        debugPrint("User Box get data is null");
        return false;
      }
      userList[element] = value;
    }

    return true;
  }

  Future<bool> createUser(String userName) async {
    UserDataModel userModel = UserDataModel(userName);

    // get box
    final overlapUser = _userBox.get(userName.toLowerCase());

    if (overlapUser != null) {
      return false;
    }

    // save data
    userName = userName.toLowerCase();
    await _userBox.put(userName, userModel);
    // user list update
    userList[userName] = userModel;

    notifyListeners();

    // debugMsg
    debugPrint("User List==============");
    for (var element in _userBox.values) {
      debugPrint(element.toString());
    }

    return true;
  }
}
