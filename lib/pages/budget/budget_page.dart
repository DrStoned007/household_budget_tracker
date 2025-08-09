import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/transaction_service.dart';
import '../../providers/transaction_provider.dart';
import '../../core/constants/categories.dart';
import '../../models/transaction_model.dart';
import '../../core/helpers/amount_input_formatter.dart';
import '../../core/helpers/currency_utils.dart';
import '../../core/constants/budget_constants.dart';
import '../../services/category_service.dart';
import '../categories/manage_categories_page.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  final Map<String, TextEditingController> _controllers = {};
  String _filter = '';

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

  Future<void> _setSameForAll(List<String> expenseCats) async {
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
            prefixText: '${getCurrencySymbol()} ',
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
      if (!mounted) return;
      setState(() {});
      messenger.showSnackBar(const SnackBar(content: Text('Budgets updated')));
    }
  }

  Future<void> _copyPreviousMonth(List<String> expenseCats) async {
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
    if (!mounted) return;
    setState(() {});
    messenger.showSnackBar(SnackBar(content: Text('Copied $copied budget${copied == 1 ? '' : 's'}')));
  }

  Future<void> _clearAllBudgets(List<String> expenseCats) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all budgets for this month?'),
        content: Text('This will clear budgets for ${DateFormat('MMM yyyy').format(_month)} for all listed categories.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) {
      for (final cat in expenseCats) {
        await TransactionService.clearMonthlyBudget(cat, _month);
        _controllers[cat]?.clear();
      }
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Budgets cleared')));
    }
  }

  void _openBudgetSheet(List<String> expenseCats, {String? preselect}) async {
    final messenger = ScaffoldMessenger.of(context);
    String? selectedCategory = preselect;
    final amountController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: StatefulBuilder(
            builder: (ctx, setLocalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add / Update Budget',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 18),
                      const SizedBox(width: 8),
                      Text(DateFormat('MMM yyyy').format(_month),
                          style: Theme.of(ctx).textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: expenseCats
                        .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setLocalState(() => selectedCategory = val),
                    validator: (val) => (val == null || val.isEmpty) ? 'Select a category' : null,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [AmountTextInputFormatter(maxDecimals: 2)],
                    decoration: InputDecoration(
                      labelText: 'Budget amount',
                      prefixText: '${getCurrencySymbol()} ',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('Save'),
                          onPressed: () async {
                            final cat = selectedCategory;
                            final raw = amountController.text.trim().replaceAll(',', '');
                            final val = double.tryParse(raw);
                            if (cat == null || cat.isEmpty) {
                              messenger.showSnackBar(const SnackBar(content: Text('Select a category')));
                              return;
                            }
                            if (val == null || val <= 0) {
                              messenger.showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
                              return;
                            }
                            await TransactionService.setMonthlyBudget(cat, _month, val);
                            // Update controller text for that category card if present
                            final c = _controllers.putIfAbsent(cat, () => TextEditingController());
                            c.text = val.toStringAsFixed(0);
                            if (!mounted) return;
                            setState(() {});
                            Navigator.pop(context);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Budget saved')));
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TransactionProvider>();
    final currency = getCurrencySymbol();
    final currencyFmt = NumberFormat.currency(symbol: currency, decimalDigits: 2);

    // Categories used for budgeting:
    // - Predefined expense categories (can be hidden/renamed)
    // - Custom expense categories from Hive (managed here)
    final customExpenseCats = CategoryService.getAll(isIncome: false).map((c) => c.name).toList();
    final disabled = CategoryService.getDisabledPredefined();
    final predefinedActive = expenseCategories.where((c) => !disabled.contains(c)).toList();
    final expenseCats = {
      ...predefinedActive,
      ...customExpenseCats,
    }.toList()
      ..sort();

    // Filtered view
    final displayedCats = _filter.trim().isEmpty
        ? expenseCats
        : (expenseCats.where((c) => c.toLowerCase().contains(_filter.trim().toLowerCase())).toList()..sort());

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
          ),
          IconButton(
            tooltip: 'Manage categories',
            icon: const Icon(Icons.category_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageCategoriesPage()),
              );
              if (!mounted) return;
              setState(() {});
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: displayedCats.length + 2,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            // Top summary + search
            final Map<String, double> budgets = {
              for (final cat in expenseCats) cat: (TransactionService.getMonthlyBudget(cat, _month) ?? 0.0)
            };
            final double totalBudget = budgets.values.fold(0.0, (a, b) => a + b);
            final double totalSpent = expenseCats.fold(0.0, (s, cat) => s + spentIn(cat));
            final double remaining = totalBudget - totalSpent;

            return Column(
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        _TotalPill(label: 'Budget', value: currencyFmt.format(totalBudget), color: Colors.blue),
                        const SizedBox(width: 8),
                        _TotalPill(label: 'Spent', value: currencyFmt.format(totalSpent), color: Colors.orange),
                        const SizedBox(width: 8),
                        _TotalPill(label: 'Remaining', value: currencyFmt.format(remaining), color: remaining >= 0 ? Colors.green : Colors.red),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search categories...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                      ),
                      onChanged: (v) => setState(() => _filter = v),
                    ),
                  ),
                ),
              ],
            );
          }
          if (index == 1) {
            // Link card to Manage Categories page
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('Manage Expense Categories'),
                subtitle: const Text('Hide, rename, or add custom categories'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManageCategoriesPage()),
                  );
                  if (!mounted) return;
                  setState(() {});
                },
              ),
            );
          }
          index -= 2;
          final cat = displayedCats[index];
          final currentBudget = TransactionService.getMonthlyBudget(cat, _month) ?? 0.0;
          final spent = spentIn(cat);
          final progress = currentBudget > 0 ? (spent / currentBudget).clamp(0, 1) : 0.0;
          final over = currentBudget > 0 && spent > currentBudget;

          return Dismissible(
            key: ValueKey('budget_$cat'),
            background: Container(
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: const Row(
                children: [Icon(Icons.save, color: Colors.green), SizedBox(width: 8), Text('Save')],
              ),
            ),
            secondaryBackground: Container(
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerRight,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [Icon(Icons.clear, color: Colors.red), SizedBox(width: 8), Text('Clear')],
              ),
            ),
            confirmDismiss: (direction) async {
              final messenger = ScaffoldMessenger.of(context);
              if (direction == DismissDirection.startToEnd) {
                // Open bottom sheet to set/update budget
                _openBudgetSheet(expenseCats, preselect: cat);
                return false;
              } else {
                // Clear budget
                if (currentBudget == 0) return false;
                await TransactionService.clearMonthlyBudget(cat, _month);
                if (!mounted) return false;
                setState(() {});
                messenger.showSnackBar(const SnackBar(content: Text('Budget cleared')));
                return false;
              }
            },
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openBudgetSheet(expenseCats, preselect: cat),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: (over
                                            ? Colors.red
                                            : (progress >= kNearLimitThreshold
                                                ? Colors.orange
                                                : theme.colorScheme.primary))
                                        .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    cat,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                if (over)
                                  _StatusChip(color: Colors.red, icon: Icons.error_outline, label: 'Over')
                                else if (!over && progress >= kNearLimitThreshold)
                                  _StatusChip(color: Colors.orange, icon: Icons.warning_amber_outlined, label: 'Near'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              currencyFmt.format(currentBudget),
                              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: progress.toDouble(),
                        minHeight: 10,
                        color: over
                            ? Colors.red
                            : (progress >= kNearLimitThreshold
                                ? Colors.orange
                                : theme.colorScheme.primary),
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _Metric(label: 'Spent', value: currencyFmt.format(spent)),
                          const SizedBox(width: 12),
                          _Metric(label: 'Budget', value: currencyFmt.format(currentBudget)),
                          const Spacer(),
                          if (over)
                            Text(
                              '+${currencyFmt.format(spent - currentBudget)}',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
                            )
                          else
                            Text(
                              '${currencyFmt.format((currentBudget - spent).clamp(0, double.infinity))} left',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            showDragHandle: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (ctx) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.account_balance_wallet),
                      title: const Text('Add/Update budget'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _openBudgetSheet(expenseCats);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.playlist_add),
                      title: const Text('Set same amount for all'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _setSameForAll(expenseCats);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.copy_all),
                      title: const Text('Copy previous month'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _copyPreviousMonth(expenseCats);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.clear_all),
                      title: const Text('Clear all budgets (this month)'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _clearAllBudgets(expenseCats);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );
        },
        icon: const Icon(Icons.more_horiz),
        label: const Text('Actions'),
      ),
    );
  }
}

class _TotalPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _TotalPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}

// Small helper widgets for card UI
class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  const _StatusChip({required this.color, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
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

