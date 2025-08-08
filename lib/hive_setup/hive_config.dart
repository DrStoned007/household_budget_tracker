// hive_config.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/currency_model.dart';

class HiveConfig {
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(TransactionModelAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(CurrencyModelAdapter());
    await Hive.openBox<TransactionModel>('transactions');
    await Hive.openBox<CategoryModel>('custom_categories');
    await Hive.openBox<CurrencyModel>('currency');
  }
}
