// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DebtLoanModelAdapter extends TypeAdapter<DebtLoanModel> {
  @override
  final int typeId = 17;

  @override
  DebtLoanModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DebtLoanModel(
      id: fields[0] as String,
      isLoan: fields[1] as bool,
      personName: fields[2] as String,
      totalAmount: fields[3] as int,
      remainingAmount: fields[4] as int?,
      dueDate: fields[5] as DateTime?,
      notes: fields[6] as String?,
      isSettled: fields[7] as bool,
      createdAt: fields[8] as DateTime?,
      colorValue: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DebtLoanModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.isLoan)
      ..writeByte(2)
      ..write(obj.personName)
      ..writeByte(3)
      ..write(obj.totalAmount)
      ..writeByte(4)
      ..write(obj.remainingAmount)
      ..writeByte(5)
      ..write(obj.dueDate)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.isSettled)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.colorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtLoanModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
