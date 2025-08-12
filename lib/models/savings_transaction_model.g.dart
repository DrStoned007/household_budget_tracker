// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'savings_transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavingsTransactionModelAdapter
    extends TypeAdapter<SavingsTransactionModel> {
  @override
  final int typeId = 10;

  @override
  SavingsTransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavingsTransactionModel(
      id: fields[0] as String,
      goalId: fields[1] as String,
      amount: fields[2] as double,
      date: fields[3] as DateTime,
      type: fields[4] as SavingsTransactionType,
      sourceTransactionId: fields[5] as String?,
      note: fields[6] as String?,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SavingsTransactionModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.goalId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.sourceTransactionId)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsTransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SavingsTransactionTypeAdapter
    extends TypeAdapter<SavingsTransactionType> {
  @override
  final int typeId = 9;

  @override
  SavingsTransactionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SavingsTransactionType.manual;
      case 1:
        return SavingsTransactionType.automatic;
      case 2:
        return SavingsTransactionType.roundup;
      case 3:
        return SavingsTransactionType.withdrawal;
      default:
        return SavingsTransactionType.manual;
    }
  }

  @override
  void write(BinaryWriter writer, SavingsTransactionType obj) {
    switch (obj) {
      case SavingsTransactionType.manual:
        writer.writeByte(0);
        break;
      case SavingsTransactionType.automatic:
        writer.writeByte(1);
        break;
      case SavingsTransactionType.roundup:
        writer.writeByte(2);
        break;
      case SavingsTransactionType.withdrawal:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsTransactionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
