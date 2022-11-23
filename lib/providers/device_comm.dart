import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class DeviceCommon {
  final ble = FlutterReactiveBle();
  late final String deviceID;

  DeviceCommon(this.deviceID);
}
