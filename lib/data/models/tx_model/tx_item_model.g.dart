// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tx_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TxItemModelAdapter extends TypeAdapter<TxItemModel> {
  @override
  final int typeId = 7;

  @override
  TxItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TxItemModel(
      name: fields[0] as String,
      amount: fields[1] as int,
      qty: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TxItemModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.qty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TxItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
