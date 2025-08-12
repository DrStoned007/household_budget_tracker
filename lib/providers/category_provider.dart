import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/supabase_category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final SupabaseCategoryService _service = SupabaseCategoryService();
  List<CategoryModel> _categories = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<CategoryModel> get categories => _categories;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  CategoryProvider() {
    loadCategories();
  }

  Future<void> loadCategories() async {
    _setLoading(true);
    final data = await _service.fetchCategories();
    _categories = data.map((cat) => CategoryModel(
      name: cat['name'],
      isIncome: cat['isIncome'] ?? false,
    )).toList();
    notifyListeners();
    _setLoading(false);
  }

  Future<void> addCategory(CategoryModel category) async {
    _setLoading(true);
    await _service.addCategory({
      'name': category.name,
      'isIncome': category.isIncome,
    });
    await loadCategories();
    _setLoading(false);
  }

  Future<void> updateCategory(int id, CategoryModel category) async {
    _setLoading(true);
    await _service.updateCategory(id, {
      'name': category.name,
      'isIncome': category.isIncome,
    });
    await loadCategories();
    _setLoading(false);
  }

  Future<void> deleteCategory(int id) async {
    _setLoading(true);
    await _service.deleteCategory(id);
    await loadCategories();
    _setLoading(false);
  }
}
