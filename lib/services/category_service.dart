import 'package:hive/hive.dart';
import '../models/category_model.dart';

class CategoryService {
  static final Box<CategoryModel> _box = Hive.box<CategoryModel>('custom_categories');

  static List<CategoryModel> getAll({bool? isIncome}) {
    final all = _box.values.toList();
    if (isIncome == null) return all;
    return all.where((cat) => cat.isIncome == isIncome).toList();
  }

  static Future<void> add(CategoryModel category) async {
    await _box.add(category);
  }

  static Future<void> delete(int key) async {
    await _box.delete(key);
  }
}
