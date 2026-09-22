// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FinancialGoalModelAdapter extends TypeAdapter<FinancialGoalModel> {
  @override
  final int typeId = 15;

  @override
  FinancialGoalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FinancialGoalModel(
      id: fields[0] as String,
      title: fields[1] as String,
      targetAmount: fields[2] as int,
      currentAmount: fields[3] as int,
      targetDate: fields[4] as DateTime?,
      colorValue: fields[5] as int,
      iconName: fields[6] as String,
      isCompleted: fields[7] as bool,
      createdAt: fields[8] as DateTime?,
      notes: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FinancialGoalModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.targetAmount)
      ..writeByte(3)
      ..write(obj.currentAmount)
      ..writeByte(4)
      ..write(obj.targetDate)
      ..writeByte(5)
      ..write(obj.colorValue)
      ..writeByte(6)
      ..write(obj.iconName)
      ..writeByte(7)
      ..write(obj.isCompleted)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinancialGoalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
