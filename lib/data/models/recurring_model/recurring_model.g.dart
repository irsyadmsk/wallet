// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringRuleModelAdapter extends TypeAdapter<RecurringRuleModel> {
  @override
  final int typeId = 10;

  @override
  RecurringRuleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringRuleModel(
      id: fields[0] as String,
      type: fields[1] as TxType,
      amount: fields[2] as int,
      accountId: fields[3] as String,
      toAccountId: fields[4] as String?,
      categoryId: fields[5] as String?,
      memo: fields[6] as String?,
      freq: fields[7] as RecurrenceFreq,
      interval: fields[8] as int,
      startDate: fields[9] as DateTime,
      endDate: fields[10] as DateTime?,
      nextRunDate: fields[11] as DateTime?,
      lastPostedDate: fields[12] as DateTime?,
      autoPost: fields[13] as bool,
      isActive: fields[14] as bool,
      externalId: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringRuleModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.accountId)
      ..writeByte(4)
      ..write(obj.toAccountId)
      ..writeByte(5)
      ..write(obj.categoryId)
      ..writeByte(6)
      ..write(obj.memo)
      ..writeByte(7)
      ..write(obj.freq)
      ..writeByte(8)
      ..write(obj.interval)
      ..writeByte(9)
      ..write(obj.startDate)
      ..writeByte(10)
      ..write(obj.endDate)
      ..writeByte(11)
      ..write(obj.nextRunDate)
      ..writeByte(12)
      ..write(obj.lastPostedDate)
      ..writeByte(13)
      ..write(obj.autoPost)
      ..writeByte(14)
      ..write(obj.isActive)
      ..writeByte(15)
      ..write(obj.externalId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringRuleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
