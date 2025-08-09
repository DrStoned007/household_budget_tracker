import 'package:hive/hive.dart';
import '../models/transaction_model.dart';

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
}
