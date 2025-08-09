import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/categories.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';
import '../categories/manage_categories_page.dart';
import '../../core/helpers/currency_utils.dart';
import '../../core/helpers/amount_input_formatter.dart';
import '../../services/transaction_service.dart';

class AddTransactionPage extends StatefulWidget {
  final TransactionType? initialType;
  final TransactionModel? initialModel;
  final int? editingKey;
  const AddTransactionPage({super.key, this.initialType, this.initialModel, this.editingKey});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  String? _category;
  double _amount = 0;
  DateTime _date = DateTime.now();
  late TransactionType _type;
  String? _note;
  final _customCategoryController = TextEditingController();
  bool _isCustomCategory = false;

  List<String> get categories {
    final customCats = CategoryService.getAll(isIncome: _type == TransactionType.income).map((c) => c.name).toList();
    return [
      ...(_type == TransactionType.income ? incomeCategories : expenseCategories),
      ...customCats,
    ];
  }

  void _resetCategory() {
    _category = null;
    _isCustomCategory = false;
    _customCategoryController.clear();
  }
  List<String> _getSuggestedCategories() {
    // Prefer last used stored list; fallback to frequency-based heuristic
    final lastUsed = TransactionService.getLastUsedCategories(_type, limit: 5);
    if (lastUsed.isNotEmpty) {
      final available = categories.toSet();
      return lastUsed.where(available.contains).toList();
    }
    final provider = context.read<TransactionProvider>();
    final relevant = provider.transactions.where((t) => t.type == _type);
    final Map<String, int> counts = {};
    for (final tx in relevant) {
      counts[tx.category] = (counts[tx.category] ?? 0) + 1;
    }
    final sorted = counts.keys.toList()
      ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));
    final available = categories.toSet();
    final result = sorted.where(available.contains).toList();
    if (result.length > 5) return result.sublist(0, 5);
    return result;
  }

  String _formatAmount(double value) {
    final f = NumberFormat.currency(symbol: getCurrencySymbol(), decimalDigits: 2);
    return f.format(value);
  }


  @override
  void initState() {
    super.initState();
    _type = widget.initialModel?.type ?? widget.initialType ?? TransactionType.expense;
    if (widget.initialModel != null) {
      final m = widget.initialModel!;
      _category = m.category;
      _amount = m.amount;
      _date = m.date;
      _note = m.note;
      _isCustomCategory = false;
    }
  }

  @override
  void dispose() {
    _customCategoryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _addCustomCategory() async {
    final name = _customCategoryController.text.trim();
    if (name.isNotEmpty) {
      final newCat = CategoryModel(name: name, isIncome: _type == TransactionType.income);
      await CategoryService.add(newCat);
      setState(() {
        _category = name;
        _isCustomCategory = false;
        _customCategoryController.clear();
      });
    }
  }

  void _reviewAndSave() {
    final pageContext = context;
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final category = _category ?? _customCategoryController.text.trim();
      final tx = TransactionModel(
        category: category,
        amount: _amount,
        date: _date,
        type: _type,
        note: _note,
      );
      final isEditing = widget.editingKey != null && widget.initialModel != null;
      showModalBottomSheet(
        context: pageContext,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (sheetContext) {
          final provider = sheetContext.watch<TransactionProvider>();
          final isSaving = provider.isLoading;
          // Calculate category spend this month and compare with budget if any
          final month = DateTime(_date.year, _date.month);
          final monthlyTx = provider.transactions
              .where((t) => t.type == TransactionType.expense && t.category == category && t.date.year == month.year && t.date.month == month.month)
              .toList();
          final spent = monthlyTx.fold<double>(0, (sum, t) => sum + t.amount);
          final budget = TransactionService.getMonthlyBudget(category, month);
          final willExceed = budget != null && (spent + (_type == TransactionType.expense ? _amount : 0)) > budget;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Review', style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Chip(
                      label: Text(_type == TransactionType.income ? 'Income' : 'Expense'),
                      avatar: Icon(_type == TransactionType.income ? Icons.arrow_downward : Icons.arrow_upward,
                          color: _type == TransactionType.income ? Colors.green : Colors.red, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(_formatAmount(_amount), style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.category_outlined),
                  title: Text(category),
                  subtitle: const Text('Category'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(DateFormat.yMMMMd().format(_date)),
                  subtitle: const Text('Date'),
                ),
                if ((_note ?? '').isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notes_outlined),
                    title: Text(_note ?? ''),
                    subtitle: const Text('Note'),
                  ),
                if (budget != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: willExceed ? Colors.red.withValues(alpha: 0.08) : Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(willExceed ? Icons.warning_amber_rounded : Icons.info_outline,
                            color: willExceed ? Colors.red : Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            willExceed
                                ? 'This expense will exceed the monthly budget of ${_formatAmount(budget)} for "$category". Spent so far: ${_formatAmount(spent)}.'
                                : 'Budget for "$category" is ${_formatAmount(budget)}. Spent so far: ${_formatAmount(spent)}.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSaving ? null : () => Navigator.pop(sheetContext),
                        child: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final provider = sheetContext.read<TransactionProvider>();
                                if (isEditing) {
                                  final key = widget.editingKey!;
                                  final previous = widget.initialModel!;
                                  await provider.updateTransaction(key, tx);
                                  if (pageContext.mounted) {
                                    ScaffoldMessenger.of(pageContext).showSnackBar(
                                      SnackBar(
                                        content: const Text('Transaction updated'),
                                        action: SnackBarAction(
                                          label: 'Undo',
                                          onPressed: () async {
                                            await pageContext.read<TransactionProvider>().updateTransaction(key, previous);
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  final key = await provider.addTransaction(tx);
                                  if (pageContext.mounted) {
                                    ScaffoldMessenger.of(pageContext).showSnackBar(
                                      SnackBar(
                                        content: const Text('Transaction added'),
                                        action: SnackBarAction(
                                          label: 'Undo',
                                          onPressed: () async {
                                            await pageContext.read<TransactionProvider>().deleteTransaction(key);
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                }
                                if (sheetContext.mounted) Navigator.pop(sheetContext);
                                if (pageContext.mounted) Navigator.pop(pageContext);
                              },
                        icon: isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check),
                        label: Text(isSaving ? 'Saving...' : (isEditing ? 'Confirm & Update' : 'Confirm & Save')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    } else {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Semantics(
            label: 'Form validation errors',
            liveRegion: true,
            child: const Text('Please review the highlighted fields.'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = context.watch<TransactionProvider>().isLoading;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editingKey != null ? 'Edit Transaction' : 'Add Transaction'),
        backgroundColor: theme.colorScheme.primary,
        elevation: 2,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth > 640 ? 600.0 : constraints.maxWidth;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            controller: _scrollController,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Type', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Expense'),
                                selected: _type == TransactionType.expense,
                                onSelected: (selected) => setState(() {
                                  _type = TransactionType.expense;
                                  _resetCategory();
                                }),
                              ),
                              ChoiceChip(
                                label: const Text('Income'),
                                selected: _type == TransactionType.income,
                                onSelected: (selected) => setState(() {
                                  _type = TransactionType.income;
                                  _resetCategory();
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text('Category', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                              ),
                              IconButton(
                                tooltip: 'Manage Categories',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ManageCategoriesPage()),
                                  ).then((_) => setState(() {}));
                                },
                                icon: const Icon(Icons.settings),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_getSuggestedCategories().isNotEmpty) ...[
                            Text('Suggested', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _getSuggestedCategories()
                                  .map((cat) => ChoiceChip(
                                        label: Text(cat),
                                        selected: _category == cat && !_isCustomCategory,
                                        onSelected: (_) => setState(() {
                                          _category = cat;
                                          _isCustomCategory = false;
                                        }),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 8),
                            Text('All', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                          ],
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...categories.map((cat) => ChoiceChip(
                                    label: Text(cat),
                                    selected: _category == cat && !_isCustomCategory,
                                    onSelected: (_) => setState(() {
                                      _category = cat;
                                      _isCustomCategory = false;
                                    }),
                                  )),
                              ActionChip(
                                avatar: const Icon(Icons.add, size: 18),
                                label: const Text('New Category'),
                                onPressed: () => setState(() {
                                  _isCustomCategory = true;
                                  _category = null;
                                }),
                              ),
                            ],
                          ),
                          if (_isCustomCategory) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _customCategoryController,
                              decoration: InputDecoration(
                                labelText: 'New Category',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.save),
                                onPressed: _addCustomCategory,
                                label: const Text('Save Category'),
                              ),
                            ),
                          ],
                          // Hidden validator for category selection
                          FormField<String>(
                            validator: (_) {
                              if (_isCustomCategory) {
                                if (_customCategoryController.text.trim().isEmpty) return 'Enter new category';
                              } else {
                                if (_category == null || _category!.isEmpty) return 'Select category';
                              }
                              return null;
                            },
                            builder: (state) => state.hasError
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(state.errorText!, style: TextStyle(color: theme.colorScheme.error)),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 16),
                          Text('Amount', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: InputDecoration(
                              hintText: '0.00',
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 12, right: 8),
                                child: Text(
                                  getCurrencySymbol(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            ),
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                            inputFormatters: [
                              AmountTextInputFormatter(maxDecimals: 2),
                            ],
                            initialValue: _amount > 0 ? _amount.toStringAsFixed(2) : null,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Enter amount';
                              final parts = val.split('.');
                              if (parts.length > 2) return 'Invalid amount';
                              if (parts.length == 2 && parts[1].length > 2) return 'Max 2 decimals allowed';
                              final numeric = val.replaceAll(',', '');
                              if (double.tryParse(numeric) == null) return 'Enter valid amount';
                              return null;
                            },
                            onSaved: (val) => _amount = double.parse(val!.replaceAll(',', '')),
                          ),
                          const SizedBox(height: 16),
                          Text('Date', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            tileColor: theme.colorScheme.surface.withValues(alpha: 0.06),
                            title: Text('Date: ${DateFormat.yMMMd().format(_date)}'),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _date,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) setState(() => _date = picked);
                            },
                          ),
                          const SizedBox(height: 16),
                          Text('Note', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: InputDecoration(
                              hintText: 'Optional note',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            minLines: 2,
                            maxLines: 4,
                            initialValue: _note ?? '',
                            onSaved: (val) => _note = val,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _reviewAndSave,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  icon: isLoading
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(isLoading ? 'Saving...' : 'Add Transaction'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
