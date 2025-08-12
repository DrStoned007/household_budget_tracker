// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'savings_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavingsSettingsModelAdapter extends TypeAdapter<SavingsSettingsModel> {
  @override
  final int typeId = 11;

  @override
  SavingsSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavingsSettingsModel(
      roundUpEnabled: fields[0] as bool,
      roundUpGoalId: fields[1] as String?,
      roundUpMultiplier: fields[2] as double,
      roundUpExpensesOnly: fields[3] as bool,
      minimumRoundUp: fields[4] as double,
      autoSaveEnabled: fields[5] as bool,
      autoSavePercentage: fields[6] as double,
      notificationsEnabled: fields[7] as bool,
      goalMilestoneNotifications: fields[8] as bool,
      weeklyProgressNotifications: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SavingsSettingsModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.roundUpEnabled)
      ..writeByte(1)
      ..write(obj.roundUpGoalId)
      ..writeByte(2)
      ..write(obj.roundUpMultiplier)
      ..writeByte(3)
      ..write(obj.roundUpExpensesOnly)
      ..writeByte(4)
      ..write(obj.minimumRoundUp)
      ..writeByte(5)
      ..write(obj.autoSaveEnabled)
      ..writeByte(6)
      ..write(obj.autoSavePercentage)
      ..writeByte(7)
      ..write(obj.notificationsEnabled)
      ..writeByte(8)
      ..write(obj.goalMilestoneNotifications)
      ..writeByte(9)
      ..write(obj.weeklyProgressNotifications);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
