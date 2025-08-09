import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'hive_setup/hive_config.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'providers/transaction_provider.dart';
import 'services/recurrence_engine.dart';
import 'services/budget_alert_service.dart';
import 'services/automation_settings_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveConfig.init();

  // Initialize notifications and request permissions
  await NotificationService.init();
  await NotificationService.requestPermissions();

  // Process recurrences and budget alerts on app start
  await RecurrenceEngine.processDueRecurrences();

  final now = DateTime.now();
  final month = DateTime(now.year, now.month);
  final alerts = await BudgetAlertService.checkAndRecord(month);
  // Show notifications for newly triggered alerts
  for (final alert in alerts) {
    await NotificationService.showBudgetAlert(alert);
  }

  // Schedule daily reminder based on settings
  final settings = await AutomationSettingsService.get();
  await NotificationService.scheduleDailyReminder(settings.dailyReminderMinutes);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: MaterialApp(
        title: 'HomeBudget Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const DashboardPage(),
      ),
    );
  }
}
