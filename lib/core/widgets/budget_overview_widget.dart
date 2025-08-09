import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/transaction_model.dart';
import '../constants/categories.dart';
import '../constants/budget_constants.dart';

import '../../services/transaction_service.dart';

class BudgetOverviewWidget extends StatelessWidget {
  final List<TransactionModel> monthlyTransactions;
  final List<TransactionModel> allTransactions;
  final DateTime month;
  final String currencySymbol;

  final bool showTopCategories;
  final bool showOnlyTopCategories;

  const BudgetOverviewWidget({
    super.key,
    required this.monthlyTransactions,
    required this.allTransactions,
    required this.month,
    required this.currencySymbol,
    this.showTopCategories = true,
    this.showOnlyTopCategories = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFmt = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);

    // Collect relevant expense categories: defaults + any used historically
    final expenseCats = {
      ...expenseCategories,
      ...allTransactions
          .where((t) => t.type == TransactionType.expense)
          .map((t) => t.category),
    }.toList()
      ..sort();

    // Compute total monthly budget across categories and track per-category budgets
    double totalBudget = 0.0;
    final Map<String, double> budgetByCategory = {};
    for (final cat in expenseCats) {
      final b = TransactionService.getMonthlyBudget(cat, month) ?? 0.0;
      if (b > 0) {
        totalBudget += b;
        budgetByCategory[cat] = b;
      }
    }

    // Compute total spent for month (expenses only)
    final double totalSpentThisMonth = monthlyTransactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (s, tx) => s + tx.amount);

    // Prepare top categories by progress
    final List<Map<String, dynamic>> items = [];
    for (final e in budgetByCategory.entries) {
      final cat = e.key;
      final budget = e.value;
      final spent = monthlyTransactions
          .where((tx) => tx.type == TransactionType.expense && tx.category == cat)
          .fold(0.0, (s, tx) => s + tx.amount);
      final progress = budget > 0 ? spent / budget : 0.0;
      items.add({
        'category': cat,
        'budget': budget,
        'spent': spent,
        'progress': progress,
      });
    }
    items.sort((a, b) => (b['progress'] as double).compareTo(a['progress'] as double));
    final top = items.take(5).toList();

    Color progressColor(double progress) {
      if (progress >= 1.0) return Colors.red;
      if (progress >= kNearLimitThreshold) return Colors.orange;
      return theme.colorScheme.primary;
    }

    Widget quickBudgetSummary() {
      if (totalBudget <= 0) return const SizedBox.shrink();
      final progress = (totalSpentThisMonth / totalBudget).clamp(0.0, 1.0).toDouble();
      final over = totalSpentThisMonth > totalBudget;
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Monthly Budget',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                color: progressColor(progress),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Spent: ${currencyFmt.format(totalSpentThisMonth)}'),
                  const SizedBox(width: 12),
                  Text('Budget: ${currencyFmt.format(totalBudget)}'),
                  const Spacer(),
                  if (over)
                    Text(
                      'Over by ${currencyFmt.format(totalSpentThisMonth - totalBudget)}',
                      style: const TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    Widget topCategoriesBudget() {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Categories Budget',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'No categories with budget set for this month.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            )
          else ...top.map((item) {
            final String cat = item['category'] as String;
            final double budget = item['budget'] as double;
            final double spent = item['spent'] as double;
            final double progress = (item['progress'] as double).clamp(0.0, 1.0).toDouble();
            final bool over = spent > budget;
            final bool near = !over && progress >= kNearLimitThreshold;
            final Color color = progressColor(progress);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(cat, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      if (over)
                        _statusChip(context, label: 'Over', color: Colors.red, icon: Icons.error_outline)
                      else if (near)
                        _statusChip(context, label: 'Near', color: Colors.orange, icon: Icons.warning_amber_outlined),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    color: color,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Spent: ${currencyFmt.format(spent)}'),
                      const SizedBox(width: 12),
                      Text('Budget: ${currencyFmt.format(budget)}'),
                      const Spacer(),
                      if (over)
                        Text(
                          '+${currencyFmt.format(spent - budget)}',
                          style: const TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ),
  );
}

    if (showOnlyTopCategories) {
      return Column(
        children: [
          if (top.isNotEmpty) topCategoriesBudget(),
        ],
      );
    }
    return Column(
      children: [
        quickBudgetSummary(),
        if (showTopCategories && top.isNotEmpty) ...[
          const SizedBox(height: 16),
          topCategoriesBudget(),
        ],
      ],
    );
  }

  Widget _statusChip(BuildContext context,
      {required String label, required Color color, required IconData icon}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}