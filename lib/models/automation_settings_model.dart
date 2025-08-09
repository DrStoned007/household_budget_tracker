// Automation and alerts settings (Hive model + adapter)
import 'package:hive/hive.dart';

@HiveType(typeId: 7)
class AutomationSettings extends HiveObject {
  // Automatically post due recurring transactions on app open
  @HiveField(0)
  bool autoPostOnOpen;

  // Daily reminder time in minutes since midnight (local) e.g., 9:30AM => 570
  @HiveField(1)
  int dailyReminderMinutes;

  // Enable budget alerts (near/over)
  @HiveField(2)
  bool alertsEnabled;

  // Near threshold (default 0.8 = 80%)
  @HiveField(3)
  double nearThreshold;

  // Over threshold (default 1.0 = 100%)
  @HiveField(4)
  double overThreshold;

  AutomationSettings({
    this.autoPostOnOpen = true,
    this.dailyReminderMinutes = 9 * 60, // 09:00
    this.alertsEnabled = true,
    this.nearThreshold = 0.8,
    this.overThreshold = 1.0,
  });
}

// Manual adapter (so we don't need build_runner)
class AutomationSettingsAdapter extends TypeAdapter<AutomationSettings> {
  @override
  final int typeId = 7;

  @override
  AutomationSettings read(BinaryReader reader) {
    final autoPostOnOpen = reader.read() as bool;
    final dailyReminderMinutes = reader.read() as int;
    final alertsEnabled = reader.read() as bool;
    final nearThreshold = reader.read() as double;
    final overThreshold = reader.read() as double;
    return AutomationSettings(
      autoPostOnOpen: autoPostOnOpen,
      dailyReminderMinutes: dailyReminderMinutes,
      alertsEnabled: alertsEnabled,
      nearThreshold: nearThreshold,
      overThreshold: overThreshold,
    );
  }

  @override
  void write(BinaryWriter writer, AutomationSettings obj) {
    writer
      ..write(obj.autoPostOnOpen)
      ..write(obj.dailyReminderMinutes)
      ..write(obj.alertsEnabled)
      ..write(obj.nearThreshold)
      ..write(obj.overThreshold);
  }
}