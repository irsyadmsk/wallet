// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tx_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TxModelAdapter extends TypeAdapter<TxModel> {
  @override
  final int typeId = 6;

  @override
  TxModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TxModel(
      id: fields[0] as String,
      type: fields[1] as TxType,
      amount: fields[2] as int,
      accountId: fields[3] as String,
      toAccountId: fields[4] as String?,
      categoryId: fields[5] as String?,
      date: fields[6] as DateTime,
      memo: fields[7] as String?,
      items: (fields[8] as List?)?.cast<TxItemModel>(),
      tagIds: (fields[9] as List?)?.cast<String>(),
      recurringRuleId: fields[10] as String?,
      isExcludedFromBudget: fields[11] as bool,
      externalId: fields[12] as String?,
      externalPairId: fields[13] as String?,
      imagePath: fields[16] as String?,
      transferFee: fields[17] as int?,
      createdBy: fields[18] as String?,
      createdByName: fields[19] as String?,
      toAmount: fields[20] as int?,
      createdAt: fields[14] as DateTime?,
      updatedAt: fields[15] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TxModel obj) {
    writer
      ..writeByte(21)
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
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.memo)
      ..writeByte(8)
      ..write(obj.items)
      ..writeByte(9)
      ..write(obj.tagIds)
      ..writeByte(10)
      ..write(obj.recurringRuleId)
      ..writeByte(11)
      ..write(obj.isExcludedFromBudget)
      ..writeByte(12)
      ..write(obj.externalId)
      ..writeByte(13)
      ..write(obj.externalPairId)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt)
      ..writeByte(16)
      ..write(obj.imagePath)
      ..writeByte(17)
      ..write(obj.transferFee)
      ..writeByte(18)
      ..write(obj.createdBy)
      ..writeByte(19)
      ..write(obj.createdByName)
      ..writeByte(20)
      ..write(obj.toAmount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TxModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
