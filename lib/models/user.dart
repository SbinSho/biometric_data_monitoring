class User {
  // User ID
  late String userID;
  // ble device ID
  late String? deviceID;
  // device collection interval
  late int interval;
  // register timestamp
  late DateTime registerTime;

  User(this.userID, this.deviceID, this.interval, this.registerTime);

  @override
  String toString() =>
      "userID : $userID, deviceID : $deviceID, interval: $interval, registerTime : $registerTime";
}
