import 'package:hive/hive.dart';

part 'savings_goal_model.g.dart';

@HiveType(typeId: 8)
class SavingsGoalModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double targetAmount;

  @HiveField(3)
  double currentAmount;

  @HiveField(4)
  DateTime? deadline;

  @HiveField(5)
  String category; // Emergency, Vacation, Car, etc.

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  bool isActive;

  @HiveField(8)
  String? description;

  @HiveField(9)
  String? iconName; // For UI representation

  SavingsGoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.deadline,
    required this.category,
    required this.createdAt,
    this.isActive = true,
    this.description,
    this.iconName,
  });

  // Helper methods
  double get progressPercentage => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, double.infinity);
  bool get isCompleted => currentAmount >= targetAmount;
  
  // Days until deadline (null if no deadline)
  int? get daysUntilDeadline {
    if (deadline == null) return null;
    final now = DateTime.now();
    final difference = deadline!.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }
}