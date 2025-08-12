import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'hive_setup/hive_config.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/auth/auth_page.dart';
import 'services/supabase_auth_service.dart';
import 'providers/transaction_provider.dart';
import 'services/recurrence_engine.dart';
import 'services/budget_alert_service.dart';
import 'services/automation_settings_service.dart';
import 'services/notification_service.dart';
import 'providers/savings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
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
        ChangeNotifierProvider(create: (_) => SavingsProvider()),
      ],
      child: MaterialApp(
        title: 'HomeBudget Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
    home: SupabaseAuthService().currentUser == null
      ? const AuthPage()
      : const DashboardPage(),
      ),
    );
  }
}
