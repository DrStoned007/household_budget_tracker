import 'package:hive/hive.dart';
import '../models/savings_goal_model.dart';
import '../models/savings_transaction_model.dart';
import 'savings_transaction_service.dart';

class SavingsGoalService {
  static final Box<SavingsGoalModel> _box = Hive.box<SavingsGoalModel>('savings_goals');
  
  // CRUD Operations
  static List<SavingsGoalModel> getAll({bool activeOnly = false}) {
    final goals = _box.values.toList();
    if (activeOnly) {
      return goals.where((goal) => goal.isActive).toList();
    }
    return goals;
  }

  static List<MapEntry<int, SavingsGoalModel>> getAllWithKeys({bool activeOnly = false}) {
    final map = _box.toMap();
    final entries = <MapEntry<int, SavingsGoalModel>>[];
    for (final e in map.entries) {
      final key = e.key;
      if (key is int) {
        if (!activeOnly || e.value.isActive) {
          entries.add(MapEntry(key, e.value));
        }
      }
    }
    return entries;
  }

  static SavingsGoalModel? getGoalById(String id) {
    try {
      return _box.values.firstWhere(
        (goal) => goal.id == id,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<String> createGoal(SavingsGoalModel goal) async {
    // Generate unique ID if not provided
    if (goal.id.isEmpty) {
      goal.id = DateTime.now().millisecondsSinceEpoch.toString();
    }
    
    await _box.add(goal);
    return goal.id;
  }

  static Future<void> updateGoal(String id, SavingsGoalModel updatedGoal) async {
    final entries = getAllWithKeys();
    for (final entry in entries) {
      if (entry.value.id == id) {
        await _box.put(entry.key, updatedGoal);
        return;
      }
    }
    throw Exception('Goal with id $id not found');
  }

  static Future<void> deleteGoal(String id) async {
    final entries = getAllWithKeys();
    for (final entry in entries) {
      if (entry.value.id == id) {
        // Also delete all transactions for this goal
        await SavingsTransactionService.deleteAllForGoal(id);
        await _box.delete(entry.key);
        return;
      }
    }
    throw Exception('Goal with id $id not found');
  }

  // Goal Operations
  static Future<void> addToGoal(String goalId, double amount, {String? note}) async {
    final goal = getGoalById(goalId);
    if (goal == null) throw Exception('Goal not found');

    // Create savings transaction
    final transaction = SavingsTransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      goalId: goalId,
      amount: amount,
      date: DateTime.now(),
      type: SavingsTransactionType.manual,
      note: note,
      createdAt: DateTime.now(),
    );

    await SavingsTransactionService.add(transaction);

    // Update goal amount
    goal.currentAmount += amount;
    await goal.save();
  }

  static Future<void> withdrawFromGoal(String goalId, double amount, {String? note}) async {
    final goal = getGoalById(goalId);
    if (goal == null) throw Exception('Goal not found');
    if (goal.currentAmount < amount) throw Exception('Insufficient funds in goal');

    // Create withdrawal transaction
    final transaction = SavingsTransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      goalId: goalId,
      amount: amount,
      date: DateTime.now(),
      type: SavingsTransactionType.withdrawal,
      note: note,
      createdAt: DateTime.now(),
    );

    await SavingsTransactionService.add(transaction);

    // Update goal amount
    goal.currentAmount -= amount;
    await goal.save();
  }

  // Analytics and Insights
  static double getGoalProgress(String goalId) {
    final goal = getGoalById(goalId);
    return goal?.progressPercentage ?? 0.0;
  }

  static List<SavingsGoalModel> getGoalsByCategory(String category) {
    return _box.values.where((goal) => goal.category == category).toList();
  }

  static double getTotalSavings({bool activeOnly = true}) {
    final goals = getAll(activeOnly: activeOnly);
    return goals.fold(0.0, (sum, goal) => sum + goal.currentAmount);
  }

  static List<SavingsGoalModel> getCompletedGoals() {
    return _box.values.where((goal) => goal.isCompleted).toList();
  }

  static List<SavingsGoalModel> getGoalsNearDeadline({int daysThreshold = 30}) {
    return _box.values.where((goal) {
      if (goal.deadline == null || goal.isCompleted) return false;
      final daysUntil = goal.daysUntilDeadline;
      return daysUntil != null && daysUntil <= daysThreshold && daysUntil >= 0;
    }).toList();
  }

  // Categories
  static List<String> getAllCategories() {
    final categories = _box.values.map((goal) => goal.category).toSet().toList();
    categories.sort();
    return categories;
  }

  static Map<String, double> getCategoryTotals() {
    final Map<String, double> totals = {};
    for (final goal in _box.values) {
      totals[goal.category] = (totals[goal.category] ?? 0.0) + goal.currentAmount;
    }
    return totals;
  }
}