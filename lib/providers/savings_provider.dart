import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Simple data models for Savings
class SavingsGoal {
  final int? id;
  final String name;
  final double targetAmount;
  final DateTime? targetDate;
  final String? status; // active, paused, achieved
  final String? color; // hex or material name
  final String? icon;
  final DateTime? createdAt;

  const SavingsGoal({
    this.id,
    required this.name,
    required this.targetAmount,
    this.targetDate,
    this.status,
    this.color,
    this.icon,
    this.createdAt,
  });

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'] as int?,
      name: (map['name'] ?? '') as String,
      targetAmount: (map['target_amount'] is num)
          ? (map['target_amount'] as num).toDouble()
          : (double.tryParse(map['target_amount']?.toString() ?? '0') ?? 0.0),
      targetDate: map['target_date'] != null && map['target_date'].toString().isNotEmpty
          ? DateTime.tryParse(map['target_date'].toString())
          : null,
      status: map['status'] as String?,
      color: map['color'] as String?,
      icon: map['icon'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }
}

class SavingsContribution {
  final int? id;
  final int goalId;
  final double amount;
  final DateTime contributedAt;
  final String? source; // manual, auto, roundup
  final int? transactionId; // optional link to transactions table if mirrored

  const SavingsContribution({
    this.id,
    required this.goalId,
    required this.amount,
    required this.contributedAt,
    this.source,
    this.transactionId,
  });

  factory SavingsContribution.fromMap(Map<String, dynamic> map) {
    return SavingsContribution(
      id: map['id'] as int?,
      goalId: (map['goal_id'] ?? map['goalId']) as int,
      amount: (map['amount'] is num)
          ? (map['amount'] as num).toDouble()
          : (double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0),
      contributedAt: map['contributed_at'] != null
          ? DateTime.tryParse(map['contributed_at'].toString()) ?? DateTime.now()
          : (map['contributedAt'] != null
              ? DateTime.tryParse(map['contributedAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      source: map['source'] as String?,
      transactionId: map['transaction_id'] as int?,
    );
  }
}

// Supabase service for savings data
class SupabaseSavingsService {
  final SupabaseClient client = Supabase.instance.client;
  final String goalsTable = 'savings_goals';
  final String contributionsTable = 'savings_contributions';

  Future<List<Map<String, dynamic>>> fetchGoals() async {
    try {
      final response = await client.from(goalsTable).select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // If table doesn't exist or RLS blocks, return empty list
      return <Map<String, dynamic>>[];
    }
  }

  Future<List<Map<String, dynamic>>> fetchContributions() async {
    try {
      final response = await client.from(contributionsTable).select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return <Map<String, dynamic>>[];
    }
  }
}

class SavingsProvider extends ChangeNotifier {
  final SupabaseSavingsService _service = SupabaseSavingsService();

  List<SavingsGoal> _goals = [];
  List<SavingsContribution> _contributions = [];
  bool _isLoading = false;

  SavingsProvider() {
    loadAll();
  }

  bool get isLoading => _isLoading;
  List<SavingsGoal> get goals => _goals;
  List<SavingsContribution> get contributions => _contributions;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  Future<void> loadAll() async {
    _setLoading(true);
    try {
      final goalsRaw = await _service.fetchGoals();
      final contRaw = await _service.fetchContributions();
      _goals = goalsRaw.map((m) => SavingsGoal.fromMap(m)).toList();
      _contributions = contRaw.map((m) => SavingsContribution.fromMap(m)).toList();
    } catch (_) {
      _goals = [];
      _contributions = [];
    }
    _setLoading(false);
  }

  double get totalSavedAll {
    return _contributions.fold<double>(0.0, (sum, c) => sum + c.amount);
  }

  double totalSavedForMonth(DateTime month) {
    final ym = DateTime(month.year, month.month);
    return _contributions
        .where((c) => c.contributedAt.year == ym.year && c.contributedAt.month == ym.month)
        .fold<double>(0.0, (sum, c) => sum + c.amount);
  }

  double totalSavedForGoal(int goalId) {
    return _contributions
        .where((c) => c.goalId == goalId)
        .fold<double>(0.0, (sum, c) => sum + c.amount);
  }
}
