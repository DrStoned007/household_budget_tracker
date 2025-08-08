import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../core/helpers/currency_utils.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  const TransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currency = getCurrencySymbol();
    return ListTile(
      leading: Icon(
        transaction.type == TransactionType.income ? Icons.arrow_downward : Icons.arrow_upward,
        color: transaction.type == TransactionType.income ? Colors.green : Colors.red,
      ),
      title: Text(transaction.category),
      subtitle: Text('$currency${transaction.amount.toStringAsFixed(2)} • ${transaction.type.name} • ${transaction.date.toLocal().toString().split(' ')[0]}'),
      trailing: transaction.note != null && transaction.note!.isNotEmpty ? Text(transaction.note!) : null,
    );
  }
}
