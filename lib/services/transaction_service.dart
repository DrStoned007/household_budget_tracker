import 'package:hive/hive.dart';
import '../models/transaction_model.dart';

class TransactionService {
  static final Box<TransactionModel> _box = Hive.box<TransactionModel>('transactions');

  static List<TransactionModel> getAll() {
    return _box.values.toList();
  }

  static Future<void> add(TransactionModel transaction) async {
    await _box.add(transaction);
  }

  static Future<void> delete(int key) async {
    await _box.delete(key);
  }

  static Future<void> update(int key, TransactionModel transaction) async {
    await _box.put(key, transaction);
  }
}
