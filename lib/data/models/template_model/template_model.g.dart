// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuickTemplateModelAdapter extends TypeAdapter<QuickTemplateModel> {
  @override
  final int typeId = 16;

  @override
  QuickTemplateModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuickTemplateModel(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as TxType,
      amount: fields[3] as int,
      categoryId: fields[4] as String?,
      accountId: fields[5] as String?,
      iconName: fields[6] as String,
      colorValue: fields[7] as int,
      orderSeq: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, QuickTemplateModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.categoryId)
      ..writeByte(5)
      ..write(obj.accountId)
      ..writeByte(6)
      ..write(obj.iconName)
      ..writeByte(7)
      ..write(obj.colorValue)
      ..writeByte(8)
      ..write(obj.orderSeq);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuickTemplateModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
