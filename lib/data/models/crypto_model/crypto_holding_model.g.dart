// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crypto_holding_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CryptoHoldingModelAdapter extends TypeAdapter<CryptoHoldingModel> {
  @override
  final int typeId = 19;

  @override
  CryptoHoldingModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CryptoHoldingModel(
      id: fields[0] as String,
      coinId: fields[1] as String,
      symbol: fields[2] as String,
      name: fields[3] as String,
      imageUrl: fields[4] as String?,
      amount: fields[5] as double,
      costBasis: fields[6] as int,
      note: fields[7] as String?,
      orderSeq: fields[8] as int,
      updatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CryptoHoldingModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.coinId)
      ..writeByte(2)
      ..write(obj.symbol)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.amount)
      ..writeByte(6)
      ..write(obj.costBasis)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.orderSeq)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CryptoHoldingModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
