import 'package:hive/hive.dart';

part 'savings_transaction_model.g.dart';

@HiveType(typeId: 9)
enum SavingsTransactionType {
  @HiveField(0)
  manual,      // User manually added money

  @HiveField(1)
  automatic,   // Automatic savings rule

  @HiveField(2)
  roundup,     // Round-up from transactions

  @HiveField(3)
  withdrawal,  // Money taken out of goal
}

@HiveType(typeId: 10)
class SavingsTransactionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String goalId;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  SavingsTransactionType type;

  @HiveField(5)
  String? sourceTransactionId; // For roundup tracking

  @HiveField(6)
  String? note;

  @HiveField(7)
  DateTime createdAt;

  SavingsTransactionModel({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    required this.type,
    this.sourceTransactionId,
    this.note,
    required this.createdAt,
  });

  bool get isDeposit => type != SavingsTransactionType.withdrawal;
  bool get isWithdrawal => type == SavingsTransactionType.withdrawal;
}