import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'budget_alert_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Notification channel ids
  static const String _channelAlertsId = 'budget_alerts';
  static const String _channelAlertsName = 'Budget Alerts';
  static const String _channelAlertsDesc = 'Near/Over budget notifications';

  static const String _channelReminderId = 'daily_reminder';
  static const String _channelReminderName = 'Daily Reminder';
  static const String _channelReminderDesc = 'Daily reminder to review budget and recurrences';

  // Notification IDs (use fixed IDs so we can update/cancel easily)
  static const int _idDailyReminder = 10001;

  static Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone database and set local timezone
    tzdata.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Fallback: default to UTC if we cannot determine local timezone
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      macOS: iosInit,
    );

    await _plugin.initialize(initSettings);

    // Create channels on Android
    const AndroidNotificationChannel alertsChannel = AndroidNotificationChannel(
      _channelAlertsId,
      _channelAlertsName,
      description: _channelAlertsDesc,
      importance: Importance.high,
    );
    const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
      _channelReminderId,
      _channelReminderName,
      description: _channelReminderDesc,
      importance: Importance.defaultImportance,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(alertsChannel);
      await android.createNotificationChannel(reminderChannel);
    }

    _initialized = true;
  }

  static Future<void> requestPermissions() async {
    // iOS/macOS permission prompt
    final darwin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (darwin != null) {
      await darwin.requestPermissions(alert: true, badge: true, sound: true);
    }
    final mac = _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    if (mac != null) {
      await mac.requestPermissions(alert: true, badge: true, sound: true);
    }
    // Android 13+ permission prompt
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
    }
  }

  // Show a budget alert notification
  static Future<void> showBudgetAlert(BudgetAlert alert) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelAlertsId,
      _channelAlertsName,
      channelDescription: _channelAlertsDesc,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.recommendation,
      ticker: 'Budget alert',
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    final bool isTotal = alert.scope == AlertScope.total;
    final String scopeLabel = isTotal ? 'Total budget' : 'Category: ${alert.category}';
    final String kind = alert.thresholdType == AlertThresholdType.over ? 'Over limit' : 'Near limit';
    final String percentTxt = (alert.percent * 100).toStringAsFixed(0);

    final String title = '$kind • $scopeLabel';
    final String body = isTotal
        ? '$percentTxt% used. Spent ${alert.spent.toStringAsFixed(2)} out of ${alert.budget.toStringAsFixed(2)}'
        : '$percentTxt% used in ${alert.category}. Spent ${alert.spent.toStringAsFixed(2)} / ${alert.budget.toStringAsFixed(2)}';

    // Use a random-ish id for category alerts to avoid overwriting, but keep within int range
    final int id = isTotal ? 20000 : (20000 + (alert.category.hashCode.abs() % 10000));

    await _plugin.show(id, title, body, details);
  }

  // Schedule or update a daily reminder at the given local minutes since midnight
  static Future<void> scheduleDailyReminder(int minutesAfterMidnight) async {
    final int hour = (minutesAfterMidnight ~/ 60) % 24;
    final int minute = minutesAfterMidnight % 60;

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelReminderId,
      _channelReminderName,
      channelDescription: _channelReminderDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ticker: 'Daily reminder',
    );
    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      _idDailyReminder,
      'Budget reminder',
      'Review your budgets and recurrences for today.',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily at this time
      payload: 'daily_reminder',
    );
  }

  static Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_idDailyReminder);
  }
}