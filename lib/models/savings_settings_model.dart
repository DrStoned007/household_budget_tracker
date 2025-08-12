import 'package:hive/hive.dart';

part 'savings_settings_model.g.dart';

@HiveType(typeId: 11)
class SavingsSettingsModel extends HiveObject {
  @HiveField(0)
  bool roundUpEnabled;

  @HiveField(1)
  String? roundUpGoalId; // Which goal receives round-ups

  @HiveField(2)
  double roundUpMultiplier; // 1.0, 2.0, 5.0, 10.0

  @HiveField(3)
  bool roundUpExpensesOnly; // Only round up expenses, not income

  @HiveField(4)
  double minimumRoundUp; // Minimum round-up amount (e.g., 0.01)

  @HiveField(5)
  bool autoSaveEnabled;

  @HiveField(6)
  double autoSavePercentage; // Percentage of income to auto-save

  @HiveField(7)
  bool notificationsEnabled;

  @HiveField(8)
  bool goalMilestoneNotifications;

  @HiveField(9)
  bool weeklyProgressNotifications;

  SavingsSettingsModel({
    this.roundUpEnabled = false,
    this.roundUpGoalId,
    this.roundUpMultiplier = 1.0,
    this.roundUpExpensesOnly = true,
    this.minimumRoundUp = 0.01,
    this.autoSaveEnabled = false,
    this.autoSavePercentage = 0.1, // 10%
    this.notificationsEnabled = true,
    this.goalMilestoneNotifications = true,
    this.weeklyProgressNotifications = false,
  });
}