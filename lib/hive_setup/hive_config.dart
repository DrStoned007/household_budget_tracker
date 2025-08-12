// hive_config.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/currency_model.dart';
import '../models/recurring_transaction_model.dart';
import '../models/automation_settings_model.dart';
import '../models/savings_goal_model.dart';
import '../models/savings_transaction_model.dart';
import '../models/savings_settings_model.dart';

class HiveConfig {
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(TransactionModelAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(CurrencyModelAdapter());
    // Recurring adapters
    Hive.registerAdapter(RecurrenceFrequencyAdapter());
    Hive.registerAdapter(RecurrenceRuleAdapter());
    Hive.registerAdapter(RecurringTransactionModelAdapter());
    // Automation settings
    Hive.registerAdapter(AutomationSettingsAdapter());
    
    // Savings adapters
    Hive.registerAdapter(SavingsGoalModelAdapter());
    Hive.registerAdapter(SavingsTransactionTypeAdapter());
    Hive.registerAdapter(SavingsTransactionModelAdapter());
    Hive.registerAdapter(SavingsSettingsModelAdapter());

    await Hive.openBox<TransactionModel>('transactions');
    await Hive.openBox<CategoryModel>('custom_categories');
    await Hive.openBox<CurrencyModel>('currency');
    await Hive.openBox<RecurringTransactionModel>('recurring_transactions');
    await Hive.openBox<AutomationSettings>('automation_settings');
    // Generic boxes for simple persisted data
    await Hive.openBox<double>('budgets'); // key: 'category|YYYY-MM' -> budget amount
    await Hive.openBox('last_used_categories'); // keys: 'income', 'expense' -> List<String>
    await Hive.openBox('automation_state'); // idempotency & alerts dedup
    await Hive.openBox('category_prefs'); // predefined categories prefs (hidden/renamed)
    
    // Savings boxes
    await Hive.openBox<SavingsGoalModel>('savings_goals');
    await Hive.openBox<SavingsTransactionModel>('savings_transactions');
    await Hive.openBox<SavingsSettingsModel>('savings_settings');
  }
}
