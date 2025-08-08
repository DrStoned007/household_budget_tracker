import 'package:hive/hive.dart';
import '../models/currency_model.dart';

class CurrencyService {
  static final Box<CurrencyModel> _box = Hive.box<CurrencyModel>('currency');

  static CurrencyModel getCurrent() {
    if (_box.isEmpty) {
      // Default to INR
      final defaultCurrency = CurrencyModel(code: 'INR', symbol: '₹');
      _box.put('selected', defaultCurrency);
      return defaultCurrency;
    }
    return _box.get('selected')!;
  }

  static Future<void> setCurrency(CurrencyModel currency) async {
    await _box.put('selected', currency);
  }
}
