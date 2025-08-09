import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class TransactionProvider extends ChangeNotifier {
  List<TransactionModel> _transactions = [];
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

  List<TransactionModel> get transactions => _transactions;
  List<MapEntry<int, TransactionModel>> get transactionsWithKeys => _transactionsWithKeys;

  Future<void> loadTransactions() async {
    _setLoading(true);
    _transactions = TransactionService.getAll();
    _transactionsWithKeys = TransactionService.getAllWithKeys();
    notifyListeners();
    _setLoading(false);
  }

  Future<int> addTransaction(TransactionModel transaction) async {
    _setLoading(true);
    final key = await TransactionService.add(transaction);
    _transactions = TransactionService.getAll();
    _transactionsWithKeys = TransactionService.getAllWithKeys();
    notifyListeners();
    _setLoading(false);
    return key;
  }

  Future<void> deleteTransaction(int key) async {
    _setLoading(true);
    await TransactionService.delete(key);
    _transactions = TransactionService.getAll();
    _transactionsWithKeys = TransactionService.getAllWithKeys();
    notifyListeners();
    _setLoading(false);
  }

  Future<void> updateTransaction(int key, TransactionModel transaction) async {
    _setLoading(true);
    await TransactionService.update(key, transaction);
    _transactions = TransactionService.getAll();
    _transactionsWithKeys = TransactionService.getAllWithKeys();
    notifyListeners();
    _setLoading(false);
  }
}
