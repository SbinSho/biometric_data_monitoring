import 'package:hive/hive.dart';

import 'hive_model.dart';

part 'biometric.g.dart';

@HiveType(typeId: HiveTypeId.biometricModel)
class BiometricModel {
  @HiveField(0)
  late final DateTime timeStamp;
  @HiveField(1)
  late final double temp;
  @HiveField(2)
  late final double heart;
  @HiveField(3)
  late final double step;

  BiometricModel(this.timeStamp, this.temp, this.heart, this.step);
}
