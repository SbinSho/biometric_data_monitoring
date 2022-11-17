// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'biometric_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BiometricModelAdapter extends TypeAdapter<BiometricModel> {
  @override
  final int typeId = 2;

  @override
  BiometricModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BiometricModel(
      fields[0] as DateTime,
      fields[1] as double,
      fields[2] as double,
      fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, BiometricModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.timeStamp)
      ..writeByte(1)
      ..write(obj.temp)
      ..writeByte(2)
      ..write(obj.heart)
      ..writeByte(3)
      ..write(obj.step);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BiometricModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
