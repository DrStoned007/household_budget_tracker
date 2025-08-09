import 'package:hive/hive.dart';

import '../core/constants/budget_constants.dart';
import '../models/automation_settings_model.dart';
import '../models/transaction_model.dart';
import 'transaction_service.dart';

enum AlertScope {
  total,
  category,
}

enum AlertThresholdType {
  near,
  over,
}

class BudgetAlert {
  final AlertScope scope;
  final String? category; // null for total
  final double spent;
  final double budget;
  final double percent; // spent / budget (0..inf)
  final AlertThresholdType thresholdType;

  BudgetAlert({
    required this.scope,
    required this.category,
    required this.spent,
    required this.budget,
    required this.percent,
    required this.thresholdType,
  });
}

class BudgetAlertService {
  static const String _automationStateBox = 'automation_state';
  static const String _settingsBox = 'automation_settings';

  /// Checks current month budgets and spent, records dedup keys in automation_state,
  /// and returns the list of newly-triggered alerts.
  ///
  /// Scope:
  /// - Total monthly budget (sum of category budgets)
  /// - Per-category budgets with budget > 0
  static Future<List<BudgetAlert>> checkAndRecord(DateTime month) async {
    final alerts = <BudgetAlert>[];
    final Box state = Hive.box(_automationStateBox);

    final settingsBox = Hive.isBoxOpen(_settingsBox)
        ? Hive.box<AutomationSettings>(_settingsBox)
        : await Hive.openBox<AutomationSettings>(_settingsBox);

    // Load or fallback to defaults
    final AutomationSettings settings =
        (settingsBox.values.isNotEmpty ? settingsBox.values.first : AutomationSettings());

    if (!settings.alertsEnabled) {
      return alerts;
    }

    final near = settings.nearThreshold.clamp(0.0, 1.0);
    final over = settings.overThreshold.clamp(0.0, 10.0); // allow >1.0 if ever used
    final nearThreshold = near == 0 ? kNearLimitThreshold : near; // default to constant if zero
    final overThreshold = over == 0 ? 1.0 : over;

    final monthKey = _monthKey(month);
    final transactions = TransactionService.getAll()
        .where((t) => t.type == TransactionType.expense && t.date.year == month.year && t.date.month == month.month)
        .toList();

    // Build budgets per category and totals
    final Set<String> categories = transactions.map((t) => t.category).toSet();

    // Collect budgets across all categories that have a configured budget (or appear in transactions)
    final Map<String, double> budgets = {};
    for (final cat in categories) {
      final b = TransactionService.getMonthlyBudget(cat, month) ?? 0.0;
      if (b > 0) {
        budgets[cat] = b;
      }
    }

    // Also include categories with budgets set but no transactions yet
    // We need to sweep all keys in budgets box for this month; skipping for performance in MVP.

    // Compute spent per category
    final Map<String, double> spentByCat = {};
    for (final t in transactions) {
      spentByCat[t.category] = (spentByCat[t.category] ?? 0.0) + t.amount;
    }

    final double totalBudget = budgets.values.fold(0.0, (s, b) => s + b);
    final double totalSpent = transactions.fold(0.0, (s, t) => s + t.amount);

    // Check total scope
    if (totalBudget > 0) {
      final percent = totalSpent / totalBudget;
      // Over first wins; else near
      if (percent >= overThreshold) {
        final key = _alertKey(monthKey, AlertScope.total, null, AlertThresholdType.over);
        if (!(state.get(key, defaultValue: false) == true)) {
          state.put(key, true);
          alerts.add(BudgetAlert(
            scope: AlertScope.total,
            category: null,
            spent: totalSpent,
            budget: totalBudget,
            percent: percent,
            thresholdType: AlertThresholdType.over,
          ));
        }
      } else if (percent >= nearThreshold) {
        final key = _alertKey(monthKey, AlertScope.total, null, AlertThresholdType.near);
        if (!(state.get(key, defaultValue: false) == true)) {
          state.put(key, true);
          alerts.add(BudgetAlert(
            scope: AlertScope.total,
            category: null,
            spent: totalSpent,
            budget: totalBudget,
            percent: percent,
            thresholdType: AlertThresholdType.near,
          ));
        }
      }
    }

    // Check per-category
    budgets.forEach((cat, budget) {
      final spent = spentByCat[cat] ?? 0.0;
      final percent = budget > 0 ? spent / budget : 0.0;
      if (percent >= overThreshold) {
        final key = _alertKey(monthKey, AlertScope.category, cat, AlertThresholdType.over);
        if (!(state.get(key, defaultValue: false) == true)) {
          state.put(key, true);
          alerts.add(BudgetAlert(
            scope: AlertScope.category,
            category: cat,
            spent: spent,
            budget: budget,
            percent: percent,
            thresholdType: AlertThresholdType.over,
          ));
        }
      } else if (percent >= nearThreshold) {
        final key = _alertKey(monthKey, AlertScope.category, cat, AlertThresholdType.near);
        if (!(state.get(key, defaultValue: false) == true)) {
          state.put(key, true);
          alerts.add(BudgetAlert(
            scope: AlertScope.category,
            category: cat,
            spent: spent,
            budget: budget,
            percent: percent,
            thresholdType: AlertThresholdType.near,
          ));
        }
      }
    });

    return alerts;
  }

  static String _alertKey(
    String monthKey,
    AlertScope scope,
    String? category,
    AlertThresholdType type,
  ) {
    final scopeStr = scope == AlertScope.total ? 'total' : 'category';
    final id = category ?? '-';
    final typeStr = type == AlertThresholdType.near ? 'near' : 'over';
    return 'alert|$monthKey|$scopeStr|$id|$typeStr';
    // Example: alert|2025-08|category|Food|near
  }

  static String _monthKey(DateTime m) => '${m.year}-${m.month.toString().padLeft(2, '0')}';
}