import 'package:hive/hive.dart';

import '../models/recurring_transaction_model.dart';
import '../models/transaction_model.dart';
import 'transaction_service.dart';

class RecurrenceEngine {
  /// Processes due recurrences and posts at most one occurrence per definition per call.
  /// Idempotency is enforced by an 'automation_state' box with keys:
  ///  - posted|recId|periodKey -> true
  static Future<void> processDueRecurrences({DateTime? now}) async {
    final DateTime nowTs = now ?? DateTime.now();
    final DateTime nowDate = DateTime(nowTs.year, nowTs.month, nowTs.day);

    final Box<RecurringTransactionModel> recBox =
        Hive.box<RecurringTransactionModel>('recurring_transactions');
    final Box stateBox = Hive.box('automation_state');

    // Iterate with keys for dedup keys
    final entries = recBox.toMap().entries
        .where((e) => e.key is int)
        .map((e) => MapEntry(e.key as int, e.value));

    for (final entry in entries) {
      final int recKey = entry.key;
      final RecurringTransactionModel rec = entry.value;

      if (!rec.enabled) continue;

      // Respect end conditions
      if (rec.rule.endDate != null) {
        final end = _atEndOfDay(rec.rule.endDate!);
        if (nowTs.isAfter(end)) {
          // Past end date, skip processing
          continue;
        }
      }
      if (rec.rule.maxCount != null && rec.runCount >= rec.rule.maxCount!) {
        // Reached max occurrences
        continue;
      }

      // Determine candidate next occurrence
      final DateTime anchor = rec.lastRunAt ?? rec.startDate;
      DateTime next = rec.nextRunAt ?? computeNextOccurrence(rec, anchor, useAnchorDay: true);

      // If next is before startDate, push to first valid after startDate
      if (!_isOnOrAfter(next, rec.startDate)) {
        next = _firstOnOrAfter(rec, rec.startDate);
      }

      // Only post if due (today or earlier)
      if (!next.isAfter(nowDate)) {
        final String pKey = periodKey(rec, next);
        final String dedupKey = 'posted|$recKey|$pKey';
        final bool alreadyPosted = stateBox.get(dedupKey, defaultValue: false) == true;

        if (!alreadyPosted) {
          // Post one occurrence
          await _postOccurrence(rec, next);
          await stateBox.put(dedupKey, true);

          // Update bookkeeping
          rec.lastRunAt = next;
          rec.runCount = rec.runCount + 1;
        }

        // Compute and store following next occurrence regardless (move forward)
        final DateTime nextAfter = computeNextOccurrence(rec, next, useAnchorDay: true);
        rec.nextRunAt = nextAfter;

        // Persist record
        await rec.save();
      } else {
        // Not due yet, just make sure nextRunAt is set forward correctly
        if (rec.nextRunAt == null) {
          rec.nextRunAt = next;
          await rec.save();
        }
      }
    }
  }

  /// Compute the next scheduled occurrence strictly after [from].
  /// For monthly frequencies, prefers startDate.day or rule.dayOfMonth if provided.
  static DateTime computeNextOccurrence(
    RecurringTransactionModel rec,
    DateTime from, {
    bool useAnchorDay = false,
  }) {
    final rule = rec.rule;
    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
        return from.add(Duration(days: rule.interval));

      case RecurrenceFrequency.weekly:
        // MVP: every N weeks on the weekday of startDate
        final int daysToAdd = 7 * rule.interval;
        DateTime candidate = from.add(Duration(days: daysToAdd));
        // Snap to startDate weekday
        final int targetWeekday = rec.startDate.weekday;
        candidate = _nextSameWeekday(candidate, targetWeekday, forward: false);
        // Ensure strictly after 'from' (in case of backward snap)
        if (!candidate.isAfter(from)) {
          candidate = candidate.add(const Duration(days: 7));
          candidate = _nextSameWeekday(candidate, targetWeekday, forward: false);
        }
        return DateTime(candidate.year, candidate.month, candidate.day);

      case RecurrenceFrequency.monthly:
        final int baseDay = rule.dayOfMonth ?? rec.startDate.day;
        final DateTime step = _addMonths(from, rule.interval);
        final DateTime snapped = _snapToMonthDay(step.year, step.month, baseDay);
        // Ensure strictly after 'from'
        if (!snapped.isAfter(from)) {
          final DateTime step2 = _addMonths(step, rule.interval);
          return _snapToMonthDay(step2.year, step2.month, baseDay);
        }
        return snapped;

      case RecurrenceFrequency.yearly:
        final int addYears = rule.interval;
        final DateTime step = DateTime(from.year + addYears, rec.startDate.month, rec.startDate.day);
        // Adjust for month day overflow (e.g., Feb 29 on non-leap)
        final DateTime corrected = _safeDate(step.year, step.month, step.day);
        if (!corrected.isAfter(from)) {
          final DateTime step2 = DateTime(step.year + addYears, rec.startDate.month, rec.startDate.day);
          return _safeDate(step2.year, step2.month, step2.day);
        }
        return corrected;
    }
  }

  /// Returns a string key representing the dedup period for the given schedule.
  /// daily: YYYY-MM-DD
  /// weekly: YYYY-Www (ISO-like week)
  /// monthly: YYYY-MM
  /// yearly: YYYY
  static String periodKey(RecurringTransactionModel rec, DateTime when) {
    final rule = rec.rule;
    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
        return '${when.year}-${twoDigits(when.month)}-${twoDigits(when.day)}';
      case RecurrenceFrequency.weekly:
        final wk = _isoWeek(when);
        return '${wk.year}-W${twoDigits(wk.week)}';
      case RecurrenceFrequency.monthly:
        return '${when.year}-${twoDigits(when.month)}';
      case RecurrenceFrequency.yearly:
        return '${when.year}';
    }
  }

  // Helpers

  static Future<void> _postOccurrence(RecurringTransactionModel rec, DateTime date) async {
    final tx = TransactionModel(
      category: rec.category,
      amount: rec.amount,
      date: DateTime(date.year, date.month, date.day),
      type: rec.type,
      note: rec.note,
    );
    await TransactionService.add(tx);
  }

  static DateTime _firstOnOrAfter(RecurringTransactionModel rec, DateTime start) {
    // Move forward until we get a first schedule >= start
    DateTime probe = rec.startDate;
    if (probe.isBefore(start)) {
      while (probe.isBefore(start)) {
        probe = computeNextOccurrence(rec, probe, useAnchorDay: true);
      }
    }
    return probe;
  }

  static bool _isOnOrAfter(DateTime a, DateTime b) =>
      !DateTime(a.year, a.month, a.day).isBefore(DateTime(b.year, b.month, b.day));

  static DateTime _atEndOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  static DateTime _nextSameWeekday(DateTime from, int weekday, {bool forward = true}) {
    // Returns the date within the same week (Mon..Sun) matching weekday; if missing, returns from.
    DateTime d = DateTime(from.year, from.month, from.day);
    int diff = weekday - d.weekday;
    if (forward && diff < 0) diff += 7;
    if (!forward && diff > 0) diff -= 7;
    return d.add(Duration(days: diff));
  }

  static DateTime _addMonths(DateTime from, int months) {
    final int y = from.year;
    final int m = from.month + months;
    final int y2 = y + ((m - 1) ~/ 12);
    final int m2 = ((m - 1) % 12) + 1;
    final int d = from.day;
    return _safeDate(y2, m2, d);
  }

  static DateTime _safeDate(int year, int month, int day) {
    final last = _lastDayOfMonth(year, month);
    final d = day > last ? last : day;
    return DateTime(year, month, d);
  }

  static int _lastDayOfMonth(int year, int month) {
    final nextMonth = month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    final lastOfMonth = nextMonth.subtract(const Duration(days: 1));
    return lastOfMonth.day;
  }

  static DateTime _snapToMonthDay(int year, int month, int dayOfMonth) {
    if (dayOfMonth == -1) {
      final int last = _lastDayOfMonth(year, month);
      return DateTime(year, month, last);
    }
    return _safeDate(year, month, dayOfMonth);
  }

  static String twoDigits(int v) => v.toString().padLeft(2, '0');

  /// Simple ISO-like week number calculation.
  /// Returns (year, week) where week is 1..53.
  static _IsoWeek _isoWeek(DateTime d) {
    // ISO week starts Monday.
    final wday = d.weekday; // 1..7
    final thursday = d.add(Duration(days: 4 - wday));
    final firstJan = DateTime(thursday.year, 1, 1);
    final diff = thursday.difference(firstJan).inDays;
    final week = (diff / 7).floor() + 1;
    return _IsoWeek(year: thursday.year, week: week);
    // Note: For dedup only; slight edge cases acceptable.
  }
}

class _IsoWeek {
  final int year;
  final int week;
  _IsoWeek({required this.year, required this.week});
}