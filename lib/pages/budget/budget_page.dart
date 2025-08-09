import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/transaction_service.dart';
import '../../providers/transaction_provider.dart';
import '../../core/constants/categories.dart';
import '../../models/transaction_model.dart';
import '../../core/helpers/amount_input_formatter.dart';
import '../../core/helpers/currency_utils.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(DateTime.now().year - 3),
      lastDate: DateTime(DateTime.now().year + 3),
      helpText: 'Select a date in the month',
    );
    if (picked != null) setState(() => _month = DateTime(picked.year, picked.month));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TransactionProvider>();
    final currency = getCurrencySymbol();
    final currencyFmt = NumberFormat.currency(symbol: currency, decimalDigits: 2);
    final expenseCats = {
      ...expenseCategories,
      ...provider.transactions
          .where((t) => t.type == TransactionType.expense)
          .map((t) => t.category),
    }.toList()
      ..sort();

    double spentIn(String cat) {
      return provider.transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.category == cat &&
              t.date.year == _month.year &&
              t.date.month == _month.month)
          .fold<double>(0, (s, t) => s + t.amount);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          TextButton.icon(
            onPressed: _pickMonth,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.calendar_month, size: 18),
            label: Text(DateFormat('MMM yyyy').format(_month)),
          )
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: expenseCats.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('Set same for all'),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final controller = TextEditingController();
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Set budget for all categories'),
                            content: TextField(
                              controller: controller,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [AmountTextInputFormatter(maxDecimals: 2)],
                              decoration: InputDecoration(
                                prefixText: '$currency ',
                                hintText: '0.00',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apply')),
                            ],
                          ),
                        );
                        if (ok == true) {
                          final raw = controller.text.replaceAll(',', '');
                          final val = double.tryParse(raw);
                          if (val == null || val <= 0) {
                            messenger.showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
                            return;
                          }
                          for (final cat in expenseCats) {
                            await TransactionService.setMonthlyBudget(cat, _month, val);
                            _controllers[cat]?.text = val.toStringAsFixed(0);
                          }
                          setState(() {});
                        }
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy_all),
                      label: const Text('Copy previous month'),
                      onPressed: () async {
                        final prev = DateTime(_month.year, _month.month - 1);
                        final messenger = ScaffoldMessenger.of(context);
                        int copied = 0;
                        for (final cat in expenseCats) {
                          final prevBudget = TransactionService.getMonthlyBudget(cat, prev);
                          if (prevBudget != null && prevBudget > 0) {
                            await TransactionService.setMonthlyBudget(cat, _month, prevBudget);
                            _controllers[cat]?.text = prevBudget.toStringAsFixed(0);
                            copied++;
                          }
                        }
                        messenger.showSnackBar(SnackBar(content: Text('Copied $copied budget${copied == 1 ? '' : 's'}')));
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            );
          }
          index -= 1;
          final cat = expenseCats[index];
          final currentBudget = TransactionService.getMonthlyBudget(cat, _month) ?? 0.0;
          final spent = spentIn(cat);
          final progress = currentBudget > 0 ? (spent / currentBudget).clamp(0, 1) : 0.0;
          final over = currentBudget > 0 && spent > currentBudget;

          final controller = _controllers.putIfAbsent(
            cat,
            () => TextEditingController(
              text: currentBudget > 0 ? currentBudget.toStringAsFixed(0) : '',
            ),
          );

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(cat, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      ),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [AmountTextInputFormatter(maxDecimals: 2)],
                          decoration: const InputDecoration(
                            labelText: 'Budget',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          final raw = controller.text.trim().replaceAll(',', '');
                          final val = double.tryParse(raw);
                          if (val == null || val <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
                            return;
                          }
                          await TransactionService.setMonthlyBudget(cat, _month, val);
                          setState(() {});
                        },
                        child: const Text('Save'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.clear),
                        onPressed: currentBudget == 0
                            ? null
                            : () async {
                                await TransactionService.clearMonthlyBudget(cat, _month);
                                controller.text = '';
                                setState(() {});
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress.toDouble(),
                    minHeight: 8,
                    color: over ? Colors.red : theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Spent: ${currencyFmt.format(spent)}'),
                      const SizedBox(width: 12),
                      Text('Budget: ${currencyFmt.format(currentBudget)}'),
                      const Spacer(),
                      if (over) Text('Over by ${currencyFmt.format(spent - currentBudget)}', style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


