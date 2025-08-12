import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/supabase_transaction_service.dart';


class TransactionProvider extends ChangeNotifier {
  final SupabaseTransactionService _service = SupabaseTransactionService();
  List<MapEntry<int, TransactionModel>> _transactionsWithKeys = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  TransactionProvider() {
    loadTransactions();
  }

  // Expose transactions as plain list for most screens
  List<TransactionModel> get transactions => _transactionsWithKeys.map((e) => e.value).toList();
  // Expose mapping with IDs for pages that need stable keys
  List<MapEntry<int, TransactionModel>> get transactionsWithKeys => _transactionsWithKeys;

  Future<void> loadTransactions() async {
    _setLoading(true);
    final data = await _service.fetchTransactions();
    _transactionsWithKeys = data.map((tx) {
      final id = (tx['id'] as num?)?.toInt() ?? -1;
      return MapEntry(
        id,
        TransactionModel(
          category: tx['category'],
          amount: (tx['amount'] as num).toDouble(),
          date: DateTime.parse(tx['date']),
          type: tx['type'] == 'income' ? TransactionType.income : TransactionType.expense,
          note: tx['note'],
        ),
      );
    }).toList();
    notifyListeners();
    _setLoading(false);
  }

  Future<int> addTransaction(TransactionModel transaction) async {
    _setLoading(true);
    final id = await _service.addTransaction({
      'category': transaction.category,
      'amount': transaction.amount,
      'date': transaction.date.toIso8601String(),
      'type': transaction.type == TransactionType.income ? 'income' : 'expense',
      'note': transaction.note,
    });
    await loadTransactions();
    _setLoading(false);
    return id;
  }

  Future<void> deleteTransaction(int id) async {
    _setLoading(true);
    await _service.deleteTransaction(id);
    await loadTransactions();
    _setLoading(false);
  }

  Future<void> updateTransaction(int id, TransactionModel transaction) async {
    _setLoading(true);
    await _service.updateTransaction(id, {
      'category': transaction.category,
      'amount': transaction.amount,
      'date': transaction.date.toIso8601String(),
      'type': transaction.type == TransactionType.income ? 'income' : 'expense',
      'note': transaction.note,
    });
    await loadTransactions();
    _setLoading(false);
  }
}
