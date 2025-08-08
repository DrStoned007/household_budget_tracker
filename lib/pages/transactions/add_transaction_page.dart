import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/categories.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';
import '../categories/manage_categories_page.dart';
import 'package:flutter/services.dart';
import '../../core/helpers/currency_utils.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  String? _category;
  double _amount = 0;
  DateTime _date = DateTime.now();
  TransactionType _type = TransactionType.expense;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        backgroundColor: theme.colorScheme.primary,
        elevation: 2,
      ),
      body: Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<TransactionType>(
                    value: _type,
                    decoration: InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: TransactionType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.name[0].toUpperCase() + type.name.substring(1)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _type = val!;
                        _category = null;
                        _isCustomCategory = false;
                        _customCategoryController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      ...categories.map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      )),
                      const DropdownMenuItem(
                        value: '__custom__',
                        child: Text('Add New Category'),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        if (val == '__custom__') {
                          _isCustomCategory = true;
                          _category = null;
                        } else {
                          _isCustomCategory = false;
                          _category = val;
                        }
                      });
                    },
                    validator: (val) {
                      if (!_isCustomCategory && (val == null || val.isEmpty)) {
                        return 'Select category';
                      }
                      return null;
                    },
                  ),
                  if (_isCustomCategory) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customCategoryController,
                      decoration: InputDecoration(
                        labelText: 'New Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Enter new category' : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.add),
                            onPressed: _addCustomCategory,
                            label: const Text('Save Category'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.settings),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ManageCategoriesPage()),
                            ).then((_) => setState(() {}));
                          },
                          label: const Text('Manage'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: getCurrencySymbol() + ' ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Enter amount';
                      final parts = val.split('.');
                      if (parts.length > 2) return 'Invalid amount';
                      if (parts.length == 2 && parts[1].length > 2) return 'Max 2 decimals allowed';
                      if (double.tryParse(val) == null) return 'Enter valid amount';
                      return null;
                    },
                    onSaved: (val) => _amount = double.parse(val!),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: theme.colorScheme.surfaceVariant,
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
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Note (optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onSaved: (val) => _note = val,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.save),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          final category = _category ?? _customCategoryController.text;
                          final tx = TransactionModel(
                            category: category,
                            amount: _amount,
                            date: _date,
                            type: _type,
                            note: _note,
                          );
                          Provider.of<TransactionProvider>(context, listen: false).addTransaction(tx);
                          Navigator.pop(context);
                        }
                      },
                      label: const Text('Add Transaction'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
