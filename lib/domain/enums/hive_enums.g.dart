// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TxTypeAdapter extends TypeAdapter<TxType> {
  @override
  final int typeId = 12;

  @override
  TxType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TxType.income;
      case 1:
        return TxType.expense;
      case 2:
        return TxType.transfer;
      default:
        return TxType.income;
    }
  }

  @override
  void write(BinaryWriter writer, TxType obj) {
    switch (obj) {
      case TxType.income:
        writer.writeByte(0);
        break;
      case TxType.expense:
        writer.writeByte(1);
        break;
      case TxType.transfer:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TxTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BudgetPeriodAdapter extends TypeAdapter<BudgetPeriod> {
  @override
  final int typeId = 13;

  @override
  BudgetPeriod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BudgetPeriod.monthly;
      default:
        return BudgetPeriod.monthly;
    }
  }

  @override
  void write(BinaryWriter writer, BudgetPeriod obj) {
    switch (obj) {
      case BudgetPeriod.monthly:
        writer.writeByte(0);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetPeriodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurrenceFreqAdapter extends TypeAdapter<RecurrenceFreq> {
  @override
  final int typeId = 14;

  @override
  RecurrenceFreq read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurrenceFreq.daily;
      case 1:
        return RecurrenceFreq.weekly;
      case 2:
        return RecurrenceFreq.monthly;
      case 3:
        return RecurrenceFreq.yearly;
      default:
        return RecurrenceFreq.daily;
    }
  }

  @override
  void write(BinaryWriter writer, RecurrenceFreq obj) {
    switch (obj) {
      case RecurrenceFreq.daily:
        writer.writeByte(0);
        break;
      case RecurrenceFreq.weekly:
        writer.writeByte(1);
        break;
      case RecurrenceFreq.monthly:
        writer.writeByte(2);
        break;
      case RecurrenceFreq.yearly:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceFreqAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
