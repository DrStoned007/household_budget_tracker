import 'package:hive/hive.dart';
import '../models/transaction_model.dart';
import '../models/savings_transaction_model.dart';
import 'savings_calculator_service.dart';
import 'savings_goal_service.dart';
import 'savings_settings_service.dart';
import 'savings_transaction_service.dart';

class TransactionService {
  static final Box<TransactionModel> _box = Hive.box<TransactionModel>('transactions');
  static final Box _lastUsedBox = Hive.box('last_used_categories');
  static final Box<double> _budgetsBox = Hive.box<double>('budgets');

  static List<TransactionModel> getAll() {
    return _box.values.toList();
  }

  static List<MapEntry<int, TransactionModel>> getAllWithKeys() {
    final map = _box.toMap();
    final entries = <MapEntry<int, TransactionModel>>[];
    for (final e in map.entries) {
      final key = e.key;
      if (key is int) {
        entries.add(MapEntry(key, e.value));
      }
    }
    return entries;
  }

  static Future<int> add(TransactionModel transaction) async {
    final key = await _box.add(transaction);
    _trackLastUsedCategory(transaction);
    
    // Process round-up savings
    await _processRoundUpSavings(transaction);
    
    return key;
  }

  static Future<void> delete(int key) async {
    await _box.delete(key);
  }

  static Future<void> update(int key, TransactionModel transaction) async {
    await _box.put(key, transaction);
    _trackLastUsedCategory(transaction);
  }

  static void _trackLastUsedCategory(TransactionModel transaction) {
    final key = transaction.type == TransactionType.income ? 'income' : 'expense';
    final List list = List<String>.from(_lastUsedBox.get(key, defaultValue: <String>[]) ?? <String>[]);
    // Move to front, unique
    list.remove(transaction.category);
    list.insert(0, transaction.category);
    // keep only top 10
    final trimmed = list.take(10).toList();
    _lastUsedBox.put(key, trimmed);
  }

  static List<String> getLastUsedCategories(TransactionType type, {int limit = 5}) {
    final key = type == TransactionType.income ? 'income' : 'expense';
    final List list = List<String>.from(_lastUsedBox.get(key, defaultValue: <String>[]) ?? <String>[]);
    if (list.length > limit) return list.take(limit).cast<String>().toList();
    return list.cast<String>().toList();
  }

  static String _budgetKey(String category, DateTime month) => '$category|${month.year}-${month.month.toString().padLeft(2, '0')}';

  static Future<void> setMonthlyBudget(String category, DateTime month, double amount) async {
    await _budgetsBox.put(_budgetKey(category, month), amount);
  }

  static double? getMonthlyBudget(String category, DateTime month) {
    return _budgetsBox.get(_budgetKey(category, month));
  }

  static Future<void> clearMonthlyBudget(String category, DateTime month) async {
    await _budgetsBox.delete(_budgetKey(category, month));
  }

  // Returns true if any month has a budget set for the given category.
  static bool hasAnyBudgetForCategory(String category) {
    for (final key in _budgetsBox.keys) {
      if (key is String && key.startsWith('$category|')) {
        final val = _budgetsBox.get(key);
        if (val != null && val > 0) return true;
      }
    }
    return false;
  }

  // Round-up processing method
  static Future<void> _processRoundUpSavings(TransactionModel transaction) async {
    try {
      final settings = SavingsSettingsService.get();
      
      // Check if round-up is enabled and applicable
      if (!settings.roundUpEnabled || settings.roundUpGoalId == null) return;
      if (settings.roundUpExpensesOnly && transaction.type != TransactionType.expense) return;
      
      // Calculate round-up amount
      final roundUpAmount = SavingsCalculatorService.calculateRoundUpWithMultiplier(transaction.amount);
      
      if (roundUpAmount <= 0) return;
      
      // Create round-up savings transaction
      final savingsTransaction = SavingsTransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        goalId: settings.roundUpGoalId!,
        amount: roundUpAmount,
        date: transaction.date,
        type: SavingsTransactionType.roundup,
        sourceTransactionId: transaction.hashCode.toString(), // Simple ID reference
        note: 'Round-up from ${transaction.category}',
        createdAt: DateTime.now(),
      );
      
      await SavingsTransactionService.add(savingsTransaction);
      
      // Update the goal amount
      final goal = SavingsGoalService.getGoalById(settings.roundUpGoalId!);
      if (goal != null) {
        goal.currentAmount += roundUpAmount;
        await goal.save();
      }
    } catch (e) {
      // Silently handle errors to not break the main transaction flow
      // In production, this should use proper logging
    }
  }
}