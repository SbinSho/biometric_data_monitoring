import 'package:permission_handler/permission_handler.dart';

class BlePermissionCheck {
  static Future<bool> permissionCheck() async {
    var result = false;

    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    for (var element in statuses.entries) {
      if (element.value.isGranted) {
        result = true;
        continue;
      } else if (element.value.isDenied) {
        result = false;
        await element.key.request();
      } else {
        result = false;
        openAppSettings();
      }
    }

    return result;
  }
}
