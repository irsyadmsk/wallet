// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BudgetModelAdapter extends TypeAdapter<BudgetModel> {
  @override
  final int typeId = 9;

  @override
  BudgetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BudgetModel(
      id: fields[0] as String,
      categoryId: fields[1] as String?,
      isTotal: fields[2] as bool,
      includeSubcategories: fields[3] as bool,
      amount: fields[4] as int,
      period: fields[5] as BudgetPeriod,
      startMonth: fields[6] as DateTime,
      endMonth: fields[7] as DateTime?,
      isArchived: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, BudgetModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.categoryId)
      ..writeByte(2)
      ..write(obj.isTotal)
      ..writeByte(3)
      ..write(obj.includeSubcategories)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.period)
      ..writeByte(6)
      ..write(obj.startMonth)
      ..writeByte(7)
      ..write(obj.endMonth)
      ..writeByte(8)
      ..write(obj.isArchived);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
