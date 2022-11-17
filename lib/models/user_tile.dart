import 'biometric.dart';
import 'user_data.dart';

class UserTileModel {
  late final UserDataModel userDataModel;
  late final List<BiometricModel>? bioDatas;

  UserTileModel(this.userDataModel, this.bioDatas);
}
