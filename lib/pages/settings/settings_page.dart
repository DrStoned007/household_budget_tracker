import 'package:flutter/material.dart';
import '../../models/currency_model.dart';
import '../../services/currency_service.dart';
import '../../models/automation_settings_model.dart';
import '../../services/automation_settings_service.dart';
import '../../services/notification_service.dart';

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
  AutomationSettings? _settings;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = CurrencyService.getCurrent();
    _loadAutomationSettings();
  }

  Future<void> _changeCurrency(CurrencyModel currency) async {
    await CurrencyService.setCurrency(currency);
    setState(() {
      _selectedCurrency = currency;
    });
  }

  // ----- Automation settings integration -----
  Future<void> _loadAutomationSettings() async {
    final s = await AutomationSettingsService.get();
    if (!mounted) return;
    setState(() {
      _settings = s;
    });
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final hh = h.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _pickReminderTime() async {
    if (_settings == null) return;
    final current = _settings!;
    final initial = TimeOfDay(
      hour: current.dailyReminderMinutes ~/ 60,
      minute: current.dailyReminderMinutes % 60,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final minutes = picked.hour * 60 + picked.minute;
      await AutomationSettingsService.setDailyReminderMinutes(minutes);
      await NotificationService.scheduleDailyReminder(minutes);
      setState(() {
        _settings!.dailyReminderMinutes = minutes;
      });
    }
  }

  Widget _buildAutomationSection() {
    final theme = Theme.of(context);
    if (_settings == null) {
      return const SizedBox.shrink();
    }
    final s = _settings!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text('Automation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Auto-post recurring on app open'),
          value: s.autoPostOnOpen,
          onChanged: (v) async {
            await AutomationSettingsService.setAutoPostOnOpen(v);
            setState(() => _settings!.autoPostOnOpen = v);
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Daily reminder time'),
          subtitle: Text(_formatMinutes(s.dailyReminderMinutes)),
          trailing: TextButton.icon(
            onPressed: _pickReminderTime,
            icon: const Icon(Icons.schedule),
            label: const Text('Change'),
          ),
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Enable budget alerts'),
          value: s.alertsEnabled,
          onChanged: (v) async {
            await AutomationSettingsService.setAlertsEnabled(v);
            setState(() => _settings!.alertsEnabled = v);
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
          child: Text(
            'Near limit threshold: ${(s.nearThreshold * 100).toStringAsFixed(0)}%',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Slider(
          value: s.nearThreshold.clamp(0.5, 1.0),
          min: 0.5,
          max: 1.0,
          divisions: 10,
          label: '${(s.nearThreshold * 100).toStringAsFixed(0)}%',
          onChanged: (v) async {
            await AutomationSettingsService.setNearThreshold(double.parse(v.toStringAsFixed(2)));
            setState(() => _settings!.nearThreshold = v);
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: Text(
            'Over limit threshold: ${(s.overThreshold * 100).toStringAsFixed(0)}%',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Slider(
          value: s.overThreshold.clamp(0.8, 1.2),
          min: 0.8,
          max: 1.2,
          divisions: 8,
          label: '${(s.overThreshold * 100).toStringAsFixed(0)}%',
          onChanged: (v) async {
            await AutomationSettingsService.setOverThreshold(double.parse(v.toStringAsFixed(2)));
            setState(() => _settings!.overThreshold = v);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.colorScheme.primary,
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Currency', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CurrencyModel>(
                    value: _selectedCurrency,
                    decoration: InputDecoration(
                      labelText: 'Select Currency',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.monetization_on, color: theme.colorScheme.primary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    icon: const Icon(Icons.arrow_drop_down_rounded, size: 28),
                    style: theme.textTheme.bodyLarge,
                    dropdownColor: theme.colorScheme.surface,
                    items: currencyOptions.map((currency) => DropdownMenuItem(
                      value: currency,
                      child: Row(
                        children: [
                          Text(currency.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Text(currency.code, style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) _changeCurrency(val);
                    },
                  ),
                ],
              ),
            ),
          ),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildAutomationSection(),
            ),
          ),
        ],
      ),
    );
  }
}
