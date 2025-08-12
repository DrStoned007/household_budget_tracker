import 'package:hive/hive.dart';
import '../models/savings_settings_model.dart';

class SavingsSettingsService {
  static final Box<SavingsSettingsModel> _box = Hive.box<SavingsSettingsModel>('savings_settings');
  static const String _settingsKey = 'user_savings_settings';

  static SavingsSettingsModel get() {
    return _box.get(_settingsKey) ?? SavingsSettingsModel();
  }

  static Future<void> update(SavingsSettingsModel settings) async {
    await _box.put(_settingsKey, settings);
  }

  static Future<void> resetToDefaults() async {
    await _box.put(_settingsKey, SavingsSettingsModel());
  }

  // Convenience methods for specific settings
  static Future<void> setRoundUpEnabled(bool enabled) async {
    final settings = get();
    settings.roundUpEnabled = enabled;
    await update(settings);
  }

  static Future<void> setRoundUpGoal(String? goalId) async {
    final settings = get();
    settings.roundUpGoalId = goalId;
    await update(settings);
  }

  static Future<void> setRoundUpMultiplier(double multiplier) async {
    final settings = get();
    settings.roundUpMultiplier = multiplier;
    await update(settings);
  }

  static Future<void> setAutoSaveEnabled(bool enabled) async {
    final settings = get();
    settings.autoSaveEnabled = enabled;
    await update(settings);
  }

  static Future<void> setAutoSavePercentage(double percentage) async {
    final settings = get();
    settings.autoSavePercentage = percentage;
    await update(settings);
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final settings = get();
    settings.notificationsEnabled = enabled;
    await update(settings);
  }
}