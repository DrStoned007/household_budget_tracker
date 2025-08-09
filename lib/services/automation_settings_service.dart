import 'package:hive/hive.dart';

import '../models/automation_settings_model.dart';

class AutomationSettingsService {
  static const String _boxName = 'automation_settings';

  static Future<Box<AutomationSettings>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<AutomationSettings>(_boxName);
    }
    return Hive.openBox<AutomationSettings>(_boxName);
  }

  static Future<AutomationSettings> get() async {
    final box = await _openBox();
    if (box.values.isNotEmpty) {
      return box.values.first;
    }
    final defaults = AutomationSettings();
    await box.add(defaults);
    return defaults;
  }

  static Future<void> save(AutomationSettings settings) async {
    final box = await _openBox();
    if (settings.isInBox) {
      await settings.save();
      return;
    }
    if (box.values.isEmpty) {
      await box.add(settings);
    } else {
      final key = box.keyAt(0);
      await box.put(key, settings);
    }
  }

  static Future<void> setAutoPostOnOpen(bool value) async {
    final s = await get();
    s.autoPostOnOpen = value;
    await s.save();
  }

  static Future<void> setDailyReminderMinutes(int minutes) async {
    final s = await get();
    s.dailyReminderMinutes = minutes;
    await s.save();
  }

  static Future<void> setAlertsEnabled(bool value) async {
    final s = await get();
    s.alertsEnabled = value;
    await s.save();
  }

  static Future<void> setNearThreshold(double value) async {
    final s = await get();
    s.nearThreshold = value;
    await s.save();
  }

  static Future<void> setOverThreshold(double value) async {
    final s = await get();
    s.overThreshold = value;
    await s.save();
  }
}