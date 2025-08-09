import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../providers/transaction_provider.dart';
import '../../core/widgets/transaction_tile.dart';
import '../../core/widgets/category_selector.dart';
import '../../models/transaction_model.dart';
import '../transactions/add_transaction_page.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String? _selectedCategory;
  TransactionType? _selectedType;
  DateTime? _selectedMonth;
  String _search = '';

  void _pickMonth() async {
    final now = DateTime.now();
    final initial = _selectedMonth ?? DateTime(now.year, now.month);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
      helpText: 'Select a date in the month',
    );
    if (picked != null) {
      setState(() => _selectedMonth = DateTime(picked.year, picked.month));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: theme.colorScheme.primary,
        elevation: 2,
        actions: [
          TextButton.icon(
            onPressed: _pickMonth,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.calendar_month, size: 18),
            label: Text(
              _selectedMonth == null
                  ? 'All time'
                  : DateFormat('MMM yyyy').format(_selectedMonth!),
            ),
          ),
          if (_selectedMonth != null)
            IconButton(
              tooltip: 'Clear month filter',
              onPressed: () => setState(() => _selectedMonth = null),
              icon: const Icon(Icons.clear),
            ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          final all = provider.transactions;
          final categories = all.map((tx) => tx.category).toSet().toList();
          // Apply filters
          var list = all.where((tx) {
            if (_selectedCategory != null && tx.category != _selectedCategory) return false;
            if (_selectedType != null && tx.type != _selectedType) return false;
            if (_selectedMonth != null && (tx.date.year != _selectedMonth!.year || tx.date.month != _selectedMonth!.month)) return false;
            if (_search.isNotEmpty) {
              final q = _search.toLowerCase();
              final note = (tx.note ?? '').toLowerCase();
              if (!tx.category.toLowerCase().contains(q) && !note.contains(q)) return false;
            }
            return true;
          }).toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          final income = list.where((t) => t.type == TransactionType.income).fold<double>(0, (s, t) => s + t.amount);
          final expense = list.where((t) => t.type == TransactionType.expense).fold<double>(0, (s, t) => s + t.amount);
          final net = income - expense;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by category or note',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _selectedType == null,
                          onSelected: (_) => setState(() => _selectedType = null),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Income'),
                          selected: _selectedType == TransactionType.income,
                          onSelected: (_) => setState(() => _selectedType = TransactionType.income),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Expense'),
                          selected: _selectedType == TransactionType.expense,
                          onSelected: (_) => setState(() => _selectedType = TransactionType.expense),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Clear filters',
                          onPressed: () => setState(() {
                            _selectedCategory = null;
                            _selectedType = null;
                            _search = '';
                          }),
                          icon: const Icon(Icons.filter_alt_off),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: CategorySelector(
                          categories: categories,
                          selectedCategory: _selectedCategory,
                          onChanged: (cat) => setState(() => _selectedCategory = cat),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _SummaryChip(label: 'Income', value: income, color: Colors.green),
                        const SizedBox(width: 8),
                        _SummaryChip(label: 'Expense', value: expense, color: Colors.red),
                        const SizedBox(width: 8),
                        _SummaryChip(label: 'Net', value: net, color: net >= 0 ? Colors.blue : Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text('No transactions found.'))
                    : RefreshIndicator(
                        onRefresh: () async => context.read<TransactionProvider>().loadTransactions(),
                        child: _SectionedTransactionList(
                          transactions: list,
                          onEdit: (key, model) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddTransactionPage(initialModel: model, editingKey: key),
                              ),
                            );
                          },
                          onDelete: (key) async {
                            // Capture dependencies before async gaps
                            final ctx = context;
                            final messenger = ScaffoldMessenger.of(ctx);
                            final provider = Provider.of<TransactionProvider>(ctx, listen: false);
                            final confirmed = await showDialog<bool>(
                              context: ctx,
                              builder: (dlg) => AlertDialog(
                                title: const Text('Delete transaction?'),
                                content: const Text('This action cannot be undone.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(dlg, false), child: const Text('Cancel')),
                                  FilledButton(onPressed: () => Navigator.pop(dlg, true), child: const Text('Delete')),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await provider.deleteTransaction(key);
                              messenger.showSnackBar(const SnackBar(content: Text('Transaction deleted')));
                            }
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionPage(initialType: _selectedType),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
          Text(value.toStringAsFixed(2), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _SectionedTransactionList extends StatelessWidget {
  final List<TransactionModel> transactions;
  final Future<void> Function(int key)? onDelete;
  final void Function(int key, TransactionModel model)? onEdit;

  const _SectionedTransactionList({
    required this.transactions,
    this.onDelete,
    this.onEdit,
  });

  String _friendlyDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(d.year, d.month, d.day);
    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('EEE, MMM d, yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    // Use provider's key mapping for stable keys
    final provider = context.read<TransactionProvider>();
    final allWithKeys = provider.transactionsWithKeys;
    final keyMap = <TransactionModel, int>{
      for (final e in allWithKeys) e.value: e.key,
    };

    final grouped = <String, List<MapEntry<int, TransactionModel>>>{};
    for (final t in transactions) {
      final label = _friendlyDate(t.date);
      final k = keyMap[t] ?? -1;
      grouped.putIfAbsent(label, () => []);
      grouped[label]!.add(MapEntry(k, t));
    }

    final sections = grouped.entries.toList();

    return ListView.builder(
      itemCount: sections.length,
      itemBuilder: (context, sectionIndex) {
        final section = sections[sectionIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(section.key, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            ),
            ...section.value.map((entry) {
              final key = entry.key;
              final model = entry.value;
              return Dismissible(
                key: ValueKey('tx_${sectionIndex}_${key}_${model.hashCode}'),
                background: Container(
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: const Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete')]),
                ),
                secondaryBackground: Container(
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerRight,
                  child: const Row(mainAxisAlignment: MainAxisAlignment.end, children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 8), Text('Edit')]),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    HapticFeedback.mediumImpact();
                    if (onDelete != null && key != -1) {
                      await onDelete!(key);
                    }
                    return false;
                  } else {
                    HapticFeedback.selectionClick();
                    if (onEdit != null && key != -1) {
                      onEdit!(key, model);
                    }
                    return false;
                  }
                },
                child: Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: TransactionTile(transaction: model),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                if (onEdit != null && key != -1) {
                                  onEdit!(key, model);
                                }
                              },
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                if (onDelete != null && key != -1) {
                                  // Use same confirm dialog flow as parent handler
                                  final ctx = context;
                                  final messenger = ScaffoldMessenger.of(ctx);
                                  final confirmed = await showDialog<bool>(
                                    context: ctx,
                                    builder: (dlg) => AlertDialog(
                                      title: const Text('Delete transaction?'),
                                      content: const Text('This action cannot be undone.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(dlg, false), child: const Text('Cancel')),
                                        FilledButton(onPressed: () => Navigator.pop(dlg, true), child: const Text('Delete')),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    await onDelete!(key);
                                    messenger.showSnackBar(const SnackBar(content: Text('Transaction deleted')));
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
