// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TagModelAdapter extends TypeAdapter<TagModel> {
  @override
  final int typeId = 8;

  @override
  TagModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TagModel(
      id: fields[0] as String,
      name: fields[1] as String,
      colorValue: fields[2] as int?,
      orderSeq: fields[3] as int,
      isArchived: fields[4] as bool,
      externalId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TagModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.colorValue)
      ..writeByte(3)
      ..write(obj.orderSeq)
      ..writeByte(4)
      ..write(obj.isArchived)
      ..writeByte(5)
      ..write(obj.externalId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
