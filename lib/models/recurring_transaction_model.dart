// Recurring transactions data model and Hive adapters
import 'package:hive/hive.dart';
import 'transaction_model.dart';


@HiveType(typeId: 4)
enum RecurrenceFrequency {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
  @HiveField(3)
  yearly,
}

@HiveType(typeId: 5)
class RecurrenceRule {
  // frequency unit
  @HiveField(0)
  final RecurrenceFrequency frequency;

  // every N units (e.g., every 2 weeks)
  @HiveField(1)
  final int interval;

  // Optional: for weekly schedules, 1..7 (Mon..Sun as per DateTime.weekday)
  @HiveField(2)
  final List<int>? byWeekday;

  // Optional: for monthly schedules, 1..31 (or -1 for last day)
  @HiveField(3)
  final int? dayOfMonth;

  // Optional: end conditions
  @HiveField(4)
  final DateTime? endDate;

  // Optional: max number of posts
  @HiveField(5)
  final int? maxCount;

  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.byWeekday,
    this.dayOfMonth,
    this.endDate,
    this.maxCount,
  }) : assert(interval >= 1);
}

@HiveType(typeId: 6)
class RecurringTransactionModel extends HiveObject {
  // Transaction shape
  @HiveField(0)
  String category;

  @HiveField(1)
  double amount;

  @HiveField(2)
  TransactionType type;

  @HiveField(3)
  String? note;

  // Recurrence info
  @HiveField(4)
  DateTime startDate;

  @HiveField(5)
  RecurrenceRule rule;

  @HiveField(6)
  bool enabled;

  // Engine bookkeeping
  @HiveField(7)
  DateTime? lastRunAt;

  @HiveField(8)
  DateTime? nextRunAt;

  @HiveField(9)
  int runCount;

  RecurringTransactionModel({
    required this.category,
    required this.amount,
    required this.type,
    this.note,
    required this.startDate,
    required this.rule,
    this.enabled = true,
    this.lastRunAt,
    this.nextRunAt,
    this.runCount = 0,
  });
}

// Manual adapters retained for stability without build_runner.
// If you later enable codegen, you can remove these and use generated adapters.

class RecurrenceFrequencyAdapter extends TypeAdapter<RecurrenceFrequency> {
  @override
  final int typeId = 4;

  @override
  RecurrenceFrequency read(BinaryReader reader) {
    final index = reader.readByte();
    switch (index) {
      case 0:
        return RecurrenceFrequency.daily;
      case 1:
        return RecurrenceFrequency.weekly;
      case 2:
        return RecurrenceFrequency.monthly;
      case 3:
        return RecurrenceFrequency.yearly;
      default:
        return RecurrenceFrequency.monthly;
    }
  }

  @override
  void write(BinaryWriter writer, RecurrenceFrequency obj) {
    switch (obj) {
      case RecurrenceFrequency.daily:
        writer.writeByte(0);
        break;
      case RecurrenceFrequency.weekly:
        writer.writeByte(1);
        break;
      case RecurrenceFrequency.monthly:
        writer.writeByte(2);
        break;
      case RecurrenceFrequency.yearly:
        writer.writeByte(3);
        break;
    }
  }
}

class RecurrenceRuleAdapter extends TypeAdapter<RecurrenceRule> {
  @override
  final int typeId = 5;

  @override
  RecurrenceRule read(BinaryReader reader) {
    // Read in fixed order
    final frequency = reader.read() as RecurrenceFrequency;
    final interval = reader.read() as int;
    final byWeekday = reader.read() as List?;
    final dayOfMonth = reader.read() as int?;
    final endDate = reader.read() as DateTime?;
    final maxCount = reader.read() as int?;
    return RecurrenceRule(
      frequency: frequency,
      interval: interval,
      byWeekday: byWeekday == null ? null : List<int>.from(byWeekday),
      dayOfMonth: dayOfMonth,
      endDate: endDate,
      maxCount: maxCount,
    );
  }

  @override
  void write(BinaryWriter writer, RecurrenceRule obj) {
    writer
      ..write(obj.frequency)
      ..write(obj.interval)
      ..write(obj.byWeekday)
      ..write(obj.dayOfMonth)
      ..write(obj.endDate)
      ..write(obj.maxCount);
  }
}

class RecurringTransactionModelAdapter extends TypeAdapter<RecurringTransactionModel> {
  @override
  final int typeId = 6;

  @override
  RecurringTransactionModel read(BinaryReader reader) {
    final category = reader.read() as String;
    final amount = reader.read() as double;
    final type = reader.read() as TransactionType;
    final note = reader.read() as String?;
    final startDate = reader.read() as DateTime;
    final rule = reader.read() as RecurrenceRule;
    final enabled = reader.read() as bool;
    final lastRunAt = reader.read() as DateTime?;
    final nextRunAt = reader.read() as DateTime?;
    final runCount = reader.read() as int;
    return RecurringTransactionModel(
      category: category,
      amount: amount,
      type: type,
      note: note,
      startDate: startDate,
      rule: rule,
      enabled: enabled,
      lastRunAt: lastRunAt,
      nextRunAt: nextRunAt,
      runCount: runCount,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringTransactionModel obj) {
    writer
      ..write(obj.category)
      ..write(obj.amount)
      ..write(obj.type)
      ..write(obj.note)
      ..write(obj.startDate)
      ..write(obj.rule)
      ..write(obj.enabled)
      ..write(obj.lastRunAt)
      ..write(obj.nextRunAt)
      ..write(obj.runCount);
  }
}