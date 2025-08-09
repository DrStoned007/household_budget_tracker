import 'package:hive/hive.dart';
import '../models/category_model.dart';

class CategoryService {
  static final Box<CategoryModel> _box = Hive.box<CategoryModel>('custom_categories');

  static List<CategoryModel> getAll({bool? isIncome}) {
    final all = _box.values.toList();
    if (isIncome == null) return all;
    return all.where((cat) => cat.isIncome == isIncome).toList();
  }

  static List<MapEntry<int, CategoryModel>> getAllWithKeys({bool? isIncome}) {
    final map = _box.toMap();
    final entries = <MapEntry<int, CategoryModel>>[];
    for (final e in map.entries) {
      final key = e.key;
      if (key is int) {
        if (isIncome == null || e.value.isIncome == isIncome) {
          entries.add(MapEntry(key, e.value));
        }
      }
    }
    return entries;
  }

  static Future<void> add(CategoryModel category) async {
    await _box.add(category);
  }

  static Future<void> update(int key, CategoryModel category) async {
    await _box.put(key, category);
  }

  static Future<void> delete(int key) async {
    await _box.delete(key);
  }

  // ---------------------------
  // Predefined expense categories preferences
  // We persist hidden/renamed predefined expense categories in a simple prefs box.
  // Key: 'disabled_predefined_expense' -> List<String> of hidden predefined names.
  static const String _kDisabledPredefinedExpense = 'disabled_predefined_expense';

  // Returns a set of hidden (disabled) predefined expense category names.
  static Set<String> getDisabledPredefined() {
    final prefs = Hive.box('category_prefs');
    final list = List<String>.from(
      prefs.get(_kDisabledPredefinedExpense, defaultValue: <String>[]) ?? <String>[],
    );
    return list.toSet();
  }

  // Hide a predefined expense category (persistently).
  static Future<void> hidePredefined(String name) async {
    final prefs = Hive.box('category_prefs');
    final set = getDisabledPredefined();
    set.add(name);
    final sorted = set.toList()..sort();
    await prefs.put(_kDisabledPredefinedExpense, sorted);
  }

  // Rename a predefined expense category:
  // - Hide the original predefined name
  // - Create a new custom expense category with the new name (expense)
  static Future<void> renamePredefined(String oldName, String newName) async {
    await hidePredefined(oldName);
    await add(CategoryModel(name: newName, isIncome: false));
  }

  // For compatibility with UIs that expect a mapping of renamed predefined categories.
  // Our current behavior is to hide the predefined and create a new custom category,
  // so we return an empty map here.
  static Map<String, String> getRenamedPredefined() {
    return <String, String>{};
  }
}
