// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsModelAdapter extends TypeAdapter<AppSettingsModel> {
  @override
  final int typeId = 11;

  @override
  AppSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettingsModel(
      themeModeIndex: fields[0] as int,
      seedColorValue: fields[1] as int,
      currencyCode: fields[2] as String,
      hideBalances: fields[3] as bool,
      onboardingDone: fields[4] as bool,
      defaultAccountId: fields[5] as String?,
      legacyDataPurged: fields[6] as bool,
      lastRecurringRunAt: fields[7] as DateTime?,
      iconShapeIndex: fields[8] as int,
      pinHash: fields[9] as String?,
      pinEnabled: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettingsModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.themeModeIndex)
      ..writeByte(1)
      ..write(obj.seedColorValue)
      ..writeByte(2)
      ..write(obj.currencyCode)
      ..writeByte(3)
      ..write(obj.hideBalances)
      ..writeByte(4)
      ..write(obj.onboardingDone)
      ..writeByte(5)
      ..write(obj.defaultAccountId)
      ..writeByte(6)
      ..write(obj.legacyDataPurged)
      ..writeByte(7)
      ..write(obj.lastRecurringRunAt)
      ..writeByte(8)
      ..write(obj.iconShapeIndex)
      ..writeByte(9)
      ..write(obj.pinHash)
      ..writeByte(10)
      ..write(obj.pinEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
