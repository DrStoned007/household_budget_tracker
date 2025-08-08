import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class TransactionProvider extends ChangeNotifier {
  List<TransactionModel> _transactions = [];

  TransactionProvider() {
    loadTransactions();
  }

  List<TransactionModel> get transactions => _transactions;

  void loadTransactions() {
    _transactions = TransactionService.getAll();
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await TransactionService.add(transaction);
    loadTransactions();
  }

  Future<void> deleteTransaction(int key) async {
    await TransactionService.delete(key);
    loadTransactions();
  }

  Future<void> updateTransaction(int key, TransactionModel transaction) async {
    await TransactionService.update(key, transaction);
    loadTransactions();
  }
}
