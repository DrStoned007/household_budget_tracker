import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';
import '../../core/constants/categories.dart';

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({super.key});

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  late List<CategoryModel> _customCategories;

  void _loadCategories() {
    setState(() {
      _customCategories = CategoryService.getAll();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    await CategoryService.delete(category.key as int);
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    final predefinedIncome =
        incomeCategories.map((c) => {'name': c, 'isIncome': true}).toList();
    final predefinedExpense =
        expenseCategories.map((c) => {'name': c, 'isIncome': false}).toList();
    final predefined = [...predefinedIncome, ...predefinedExpense];
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Predefined Categories',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ...predefined.map(
              (cat) => Card(
                child: ListTile(
                  title: Text(cat['name'] as String),
                  subtitle:
                      Text((cat['isIncome'] as bool) ? 'Income' : 'Expense'),
                  trailing: const Text('Predefined',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Custom Categories',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (_customCategories.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No custom categories added.'),
              ),
            ..._customCategories.map(
              (cat) => Card(
                child: ListTile(
                  title: Text(cat.name),
                  subtitle: Text(cat.isIncome ? 'Income' : 'Expense'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _deleteCategory(cat);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
