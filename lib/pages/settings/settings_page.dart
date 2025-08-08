import 'package:flutter/material.dart';
import '../../models/currency_model.dart';
import '../../services/currency_service.dart';

final currencyOptions = [
  CurrencyModel(code: 'MYR', symbol: 'RM'),
  CurrencyModel(code: 'INR', symbol: '₹'),
  CurrencyModel(code: 'USD', symbol: '\$'),
  CurrencyModel(code: 'EUR', symbol: '€'),
  CurrencyModel(code: 'JPY', symbol: '¥'),
];

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late CurrencyModel _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = CurrencyService.getCurrent();
  }

  Future<void> _changeCurrency(CurrencyModel currency) async {
    await CurrencyService.setCurrency(currency);
    setState(() {
      _selectedCurrency = currency;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Currency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<CurrencyModel>(
              value: _selectedCurrency,
              decoration: const InputDecoration(labelText: 'Select Currency'),
              items: currencyOptions.map((currency) => DropdownMenuItem(
                value: currency,
                child: Text('${currency.symbol} ${currency.code}'),
              )).toList(),
              onChanged: (val) {
                if (val != null) _changeCurrency(val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
