// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tx_category_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TxCategoryModelAdapter extends TypeAdapter<TxCategoryModel> {
  @override
  final int typeId = 5;

  @override
  TxCategoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TxCategoryModel(
      id: fields[0] as String,
      name: fields[1] as String,
      emoji: fields[2] as String?,
      typeCode: fields[3] as int,
      parentId: fields[4] as String?,
      iconPath: fields[5] as String?,
      colorValue: fields[6] as int,
      orderSeq: fields[7] as int,
      isArchived: fields[8] as bool,
      externalId: fields[9] as String?,
      createdAt: fields[10] as DateTime?,
      updatedAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TxCategoryModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.typeCode)
      ..writeByte(4)
      ..write(obj.parentId)
      ..writeByte(5)
      ..write(obj.iconPath)
      ..writeByte(6)
      ..write(obj.colorValue)
      ..writeByte(7)
      ..write(obj.orderSeq)
      ..writeByte(8)
      ..write(obj.isArchived)
      ..writeByte(9)
      ..write(obj.externalId)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TxCategoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
