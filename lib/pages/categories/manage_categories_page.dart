import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';
import '../../services/transaction_service.dart';
import '../../core/constants/categories.dart';
import 'package:intl/intl.dart';

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({super.key});

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  final TextEditingController _newCatCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _newCatCtrl.dispose();
    super.dispose();
  }

  // Build active predefined expense categories list applying user prefs (disabled/renamed)
  List<String> _activePredefinedExpense() {
    final disabled = CategoryService.getDisabledPredefined();
    final renamed = CategoryService.getRenamedPredefined();
    final result = <String>[];
    for (final base in expenseCategories) {
      if (disabled.contains(base)) continue;
      final name = renamed[base] ?? base;
      result.add(name);
    }
    return result;
  }

  // Utilities
  Set<String> _allExpenseNamesLowerExcluding({String? exclude}) {
    final set = <String>{};
    // Predefined: include renamed names for active ones
    for (final n in _activePredefinedExpense()) {
      if (exclude != null && n.toLowerCase() == exclude.toLowerCase()) continue;
      set.add(n.toLowerCase());
    }
    // Custom expense
    for (final c in CategoryService.getAll(isIncome: false)) {
      if (exclude != null && c.name.toLowerCase() == exclude.toLowerCase()) continue;
      set.add(c.name.toLowerCase());
    }
    return set;
  }

  Future<void> _addCustomExpense() async {
    final messenger = ScaffoldMessenger.of(context);
    final name = _newCatCtrl.text.trim();
    if (name.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Enter a category name')));
      return;
    }
    final exists = _allExpenseNamesLowerExcluding().contains(name.toLowerCase());
    if (exists) {
      messenger.showSnackBar(const SnackBar(content: Text('Category already exists')));
      return;
    }
    await CategoryService.add(CategoryModel(name: name, isIncome: false));
    _newCatCtrl.clear();
    if (!mounted) return;
    setState(() {});
    messenger.showSnackBar(const SnackBar(content: Text('Category added')));
  }

  Future<void> _renameCustom(int key, CategoryModel cat) async {
    final controller = TextEditingController(text: cat.name);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (!mounted) return;
    if (ok == true) {
      final name = controller.text.trim();
      if (name.isEmpty) {
        messenger.showSnackBar(const SnackBar(content: Text('Enter a valid name')));
        return;
      }
      final exists = _allExpenseNamesLowerExcluding(exclude: cat.name).contains(name.toLowerCase());
      if (exists) {
        messenger.showSnackBar(const SnackBar(content: Text('Category already exists')));
        return;
      }
      await CategoryService.update(key, CategoryModel(name: name, isIncome: false));
      setState(() {});
      messenger.showSnackBar(const SnackBar(content: Text('Category renamed')));
    }
  }

  Future<void> _deleteCustom(int key, CategoryModel cat) async {
    final messenger = ScaffoldMessenger.of(context);
    // Prevent deletion if any budget exists for this category (across any month)
    final hasBudget = TransactionService.hasAnyBudgetForCategory(cat.name);
    if (hasBudget) {
      await showDialog<void>(
        context: context,
        builder: (dlg) => AlertDialog(
          title: const Text('Cannot delete'),
          content: const Text('This category has budgets set. Clear them first before deleting.'),
          actions: [TextButton(onPressed: () => Navigator.pop(dlg), child: const Text('OK'))],
        ),
      );
      if (!mounted) return;
      return;
    }
 
    final ok = await showDialog<bool>(
      context: context,
      builder: (dlg) => AlertDialog(
        title: const Text('Delete category?'),
        content: const Text('This will not affect past transactions.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dlg, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dlg, true), child: const Text('Delete')),
        ],
      ),
    );
    if (!mounted) return;
    if (ok == true) {
      await CategoryService.delete(key);
      if (!mounted) return;
      setState(() {});
      messenger.showSnackBar(const SnackBar(content: Text('Category deleted')));
    }
  }

  Future<void> _renamePredefined(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (!mounted) return;
    if (ok == true) {
      final newName = controller.text.trim();
      if (newName.isEmpty) {
        messenger.showSnackBar(const SnackBar(content: Text('Enter a valid name')));
        return;
      }
      final exists = _allExpenseNamesLowerExcluding(exclude: oldName).contains(newName.toLowerCase());
      if (exists) {
        messenger.showSnackBar(const SnackBar(content: Text('Category already exists')));
        return;
      }
      await CategoryService.renamePredefined(oldName, newName);
      setState(() {});
      messenger.showSnackBar(const SnackBar(content: Text('Category renamed')));
    }
  }

  Future<void> _deletePredefined(String name) async {
    final messenger = ScaffoldMessenger.of(context);
    // Prevent deletion if any budget exists for this category (across any month)
    final hasBudget = TransactionService.hasAnyBudgetForCategory(name);
    if (hasBudget) {
      await showDialog<void>(
        context: context,
        builder: (dlg) => AlertDialog(
          title: const Text('Cannot delete'),
          content: const Text('This category has budgets set. Clear them first before deleting.'),
          actions: [TextButton(onPressed: () => Navigator.pop(dlg), child: const Text('OK'))],
        ),
      );
      if (!mounted) return;
      return;
    }
 
    final ok = await showDialog<bool>(
      context: context,
      builder: (dlg) => AlertDialog(
        title: const Text('Delete category?'),
        content: const Text('This will not affect past transactions.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dlg, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dlg, true), child: const Text('Delete')),
        ],
      ),
    );
    if (!mounted) return;
    if (ok == true) {
      await CategoryService.hidePredefined(name);
      if (!mounted) return;
      setState(() {});
      messenger.showSnackBar(const SnackBar(content: Text('Category deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customExpenseEntries = CategoryService.getAllWithKeys(isIncome: false);
    final activePredefined = _activePredefinedExpense();

    // Build unified list for display and filter
    final items = <_ManagedCat>[
      ...activePredefined.map((n) => _ManagedCat(name: n, isPredefined: true, key: null)),
      ...customExpenseEntries.map((e) => _ManagedCat(name: e.value.name, isPredefined: false, key: e.key)),
    ];

    // Apply search filter
    final filtered = _search.trim().isEmpty
        ? items
        : items.where((i) => i.name.toLowerCase().contains(_search.toLowerCase())).toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Expense Categories'),
        actions: [
          // Current month info for user clarity when blocking deletion by month budgets if we ever show it here
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: Text(DateFormat('MMM yyyy').format(DateTime.now()),
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Add custom category
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newCatCtrl,
                          decoration: const InputDecoration(
                            labelText: 'New expense category',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _addCustomExpense,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search categories',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Center(child: Text('No categories'))
          else
            ...filtered.map((item) {
              // Swipe actions like transaction cards
              return Dismissible(
                key: ValueKey('cat_${item.isPredefined ? 'pre' : 'cus'}_${item.key ?? item.name}'),
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: const Row(
                    children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete')],
                  ),
                ),
                secondaryBackground: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerRight,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 8), Text('Edit')],
                  ),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    // delete
                    if (item.isPredefined) {
                      await _deletePredefined(item.name);
                    } else {
                      final entry = customExpenseEntries.firstWhere((e) => e.key == item.key, orElse: () => MapEntry(-1, CategoryModel(name: '', isIncome: false)));
                      if (entry.key != -1) {
                        await _deleteCustom(entry.key, entry.value);
                      }
                    }
                    return false;
                  } else {
                    // edit
                    if (item.isPredefined) {
                      await _renamePredefined(item.name);
                    } else {
                      final entry = customExpenseEntries.firstWhere((e) => e.key == item.key, orElse: () => MapEntry(-1, CategoryModel(name: '', isIncome: false)));
                      if (entry.key != -1) {
                        await _renameCustom(entry.key, entry.value);
                      }
                    }
                    return false;
                  }
                },
                child: Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: item.isPredefined ? Colors.blue.withValues(alpha: 0.12) : Colors.green.withValues(alpha: 0.12),
                      child: Icon(item.isPredefined ? Icons.star : Icons.label, color: item.isPredefined ? Colors.blue : Colors.green),
                    ),
                    title: Text(item.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                    subtitle: Text(item.isPredefined ? 'Predefined • Expense' : 'Custom • Expense'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            if (item.isPredefined) {
                              await _renamePredefined(item.name);
                            } else {
                              final entry = customExpenseEntries.firstWhere((e) => e.key == item.key, orElse: () => MapEntry(-1, CategoryModel(name: '', isIncome: false)));
                              if (entry.key != -1) await _renameCustom(entry.key, entry.value);
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            if (item.isPredefined) {
                              await _deletePredefined(item.name);
                            } else {
                              final entry = customExpenseEntries.firstWhere((e) => e.key == item.key, orElse: () => MapEntry(-1, CategoryModel(name: '', isIncome: false)));
                              if (entry.key != -1) await _deleteCustom(entry.key, entry.value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ManagedCat {
  final String name;
  final bool isPredefined;
  final int? key; // for custom
  _ManagedCat({required this.name, required this.isPredefined, required this.key});
}
