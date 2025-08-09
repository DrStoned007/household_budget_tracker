import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../core/helpers/currency_utils.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  const TransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currency = getCurrencySymbol();
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.red;
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: color),
        ),
        title: Text(transaction.category, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '$currency${transaction.amount.toStringAsFixed(2)} • ${isIncome ? 'income' : 'expense'} • ${transaction.date.toLocal().toString().split(' ')[0]}',
        ),
        trailing: transaction.note != null && transaction.note!.isNotEmpty ? Text(transaction.note!, overflow: TextOverflow.ellipsis) : null,
      ),
    );
  }
}
