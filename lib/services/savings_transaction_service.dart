import 'package:hive/hive.dart';
import '../models/savings_transaction_model.dart';

class SavingsTransactionService {
  static final Box<SavingsTransactionModel> _box = Hive.box<SavingsTransactionModel>('savings_transactions');

  // CRUD Operations
  static List<SavingsTransactionModel> getAll() {
    return _box.values.toList();
  }

  static List<MapEntry<int, SavingsTransactionModel>> getAllWithKeys() {
    final map = _box.toMap();
    final entries = <MapEntry<int, SavingsTransactionModel>>[];
    for (final e in map.entries) {
      final key = e.key;
      if (key is int) {
        entries.add(MapEntry(key, e.value));
      }
    }
    return entries;
  }

  static Future<int> add(SavingsTransactionModel transaction) async {
    return await _box.add(transaction);
  }

  static Future<void> delete(int key) async {
    await _box.delete(key);
  }

  static Future<void> update(int key, SavingsTransactionModel transaction) async {
    await _box.put(key, transaction);
  }

  // Goal-specific operations
  static List<SavingsTransactionModel> getTransactionsForGoal(String goalId) {
    return _box.values.where((transaction) => transaction.goalId == goalId).toList();
  }

  static Future<void> deleteAllForGoal(String goalId) async {
    final entries = getAllWithKeys();
    final keysToDelete = <int>[];
    
    for (final entry in entries) {
      if (entry.value.goalId == goalId) {
        keysToDelete.add(entry.key);
      }
    }
    
    for (final key in keysToDelete) {
      await _box.delete(key);
    }
  }

  // Analytics
  static double getTotalDepositsForGoal(String goalId) {
    return _box.values
        .where((t) => t.goalId == goalId && t.isDeposit)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  static double getTotalWithdrawalsForGoal(String goalId) {
    return _box.values
        .where((t) => t.goalId == goalId && t.isWithdrawal)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  static List<SavingsTransactionModel> getTransactionsByType(SavingsTransactionType type) {
    return _box.values.where((t) => t.type == type).toList();
  }

  static List<SavingsTransactionModel> getTransactionsInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _box.values.where((t) {
      return t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
             t.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Round-up specific
  static List<SavingsTransactionModel> getRoundUpTransactions() {
    return getTransactionsByType(SavingsTransactionType.roundup);
  }

  static double getTotalRoundUpSavings() {
    return getRoundUpTransactions().fold(0.0, (sum, t) => sum + t.amount);
  }
}