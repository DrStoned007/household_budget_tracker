import 'dart:math';
import '../models/transaction_model.dart';
import '../models/savings_goal_model.dart';
import 'savings_settings_service.dart';

class SavingsCalculatorService {
  // Round-up calculations
  static double calculateRoundUp(double amount) {
    if (amount <= 0) return 0.0;
    
    final roundedUp = (amount.ceil()).toDouble();
    final roundUpAmount = roundedUp - amount;
    
    // Apply minimum round-up threshold
    final settings = SavingsSettingsService.get();
    if (roundUpAmount < settings.minimumRoundUp) {
      return settings.minimumRoundUp;
    }
    
    return roundUpAmount;
  }

  static double calculateRoundUpWithMultiplier(double amount) {
    final baseRoundUp = calculateRoundUp(amount);
    final settings = SavingsSettingsService.get();
    return baseRoundUp * settings.roundUpMultiplier;
  }

  // Auto-save calculations
  static double calculateAutoSaveAmount(List<TransactionModel> recentTransactions) {
    final settings = SavingsSettingsService.get();
    if (!settings.autoSaveEnabled) return 0.0;

    // Calculate total income from recent transactions
    final totalIncome = recentTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    return totalIncome * settings.autoSavePercentage;
  }

  // Affordability checks
  static bool canAffordToSave(double amount, List<TransactionModel> recentTransactions) {
    if (amount <= 0) return true;

    // Calculate recent income vs expenses
    final totalIncome = recentTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final totalExpenses = recentTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final availableAmount = totalIncome - totalExpenses;
    
    // Conservative check: only allow saving if we have at least 20% buffer
    return availableAmount > (amount * 1.2);
  }

  // Goal projections
  static Map<String, dynamic> getGoalProjections(SavingsGoalModel goal) {
    final projections = <String, dynamic>{};
    
    // Current progress
    projections['currentProgress'] = goal.progressPercentage;
    projections['remainingAmount'] = goal.remainingAmount;
    
    // Time-based projections
    if (goal.deadline != null) {
      final daysUntilDeadline = goal.daysUntilDeadline ?? 0;
      if (daysUntilDeadline > 0) {
        final dailyAmountNeeded = goal.remainingAmount / daysUntilDeadline;
        final weeklyAmountNeeded = dailyAmountNeeded * 7;
        final monthlyAmountNeeded = dailyAmountNeeded * 30;
        
        projections['dailyAmountNeeded'] = dailyAmountNeeded;
        projections['weeklyAmountNeeded'] = weeklyAmountNeeded;
        projections['monthlyAmountNeeded'] = monthlyAmountNeeded;
        projections['isAchievable'] = _isGoalAchievable(goal, dailyAmountNeeded);
      }
    }
    
    // Completion estimates based on current savings rate
    final completionEstimate = _estimateCompletionDate(goal);
    if (completionEstimate != null) {
      projections['estimatedCompletionDate'] = completionEstimate;
    }
    
    return projections;
  }

  // Smart savings suggestions
  static Map<String, dynamic> getSavingsSuggestions(
    List<TransactionModel> recentTransactions,
    List<SavingsGoalModel> goals,
  ) {
    final suggestions = <String, dynamic>{};
    
    // Analyze spending patterns
    final spendingAnalysis = _analyzeSpendingPatterns(recentTransactions);
    suggestions['spendingAnalysis'] = spendingAnalysis;
    
    // Suggest round-up potential
    final roundUpPotential = _calculateRoundUpPotential(recentTransactions);
    suggestions['roundUpPotential'] = roundUpPotential;
    
    // Suggest optimal savings amount
    final optimalSavingsAmount = _calculateOptimalSavingsAmount(recentTransactions);
    suggestions['optimalSavingsAmount'] = optimalSavingsAmount;
    
    // Goal prioritization suggestions
    final goalPriorities = _suggestGoalPriorities(goals);
    suggestions['goalPriorities'] = goalPriorities;
    
    return suggestions;
  }

  // Private helper methods
  static bool _isGoalAchievable(SavingsGoalModel goal, double dailyAmountNeeded) {
    // Simple heuristic: if daily amount needed is more than $50, flag as potentially difficult
    return dailyAmountNeeded <= 50.0;
  }

  static DateTime? _estimateCompletionDate(SavingsGoalModel goal) {
    // This would require historical data to calculate savings rate
    // For now, return null - can be enhanced later with transaction history
    return null;
  }

  static Map<String, dynamic> _analyzeSpendingPatterns(List<TransactionModel> transactions) {
    final analysis = <String, dynamic>{};
    
    // Category spending
    final categorySpending = <String, double>{};
    for (final transaction in transactions.where((t) => t.type == TransactionType.expense)) {
      categorySpending[transaction.category] = 
          (categorySpending[transaction.category] ?? 0.0) + transaction.amount;
    }
    
    analysis['categorySpending'] = categorySpending;
    if (categorySpending.isNotEmpty) {
      analysis['topSpendingCategory'] = categorySpending.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }
    
    return analysis;
  }

  static double _calculateRoundUpPotential(List<TransactionModel> transactions) {
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + calculateRoundUp(t.amount));
  }

  static double _calculateOptimalSavingsAmount(List<TransactionModel> transactions) {
    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final totalExpenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final surplus = totalIncome - totalExpenses;
    
    // Suggest saving 20% of surplus, but at least 10% of income
    final surplusSavings = surplus * 0.2;
    final incomeSavings = totalIncome * 0.1;
    
    return max(surplusSavings, incomeSavings);
  }

  static List<Map<String, dynamic>> _suggestGoalPriorities(List<SavingsGoalModel> goals) {
    final priorities = <Map<String, dynamic>>[];
    
    for (final goal in goals) {
      final priority = <String, dynamic>{};
      priority['goal'] = goal;
      
      // Priority score based on deadline urgency and completion percentage
      double score = 0.0;
      
      // Deadline urgency (higher score for closer deadlines)
      if (goal.deadline != null) {
        final daysUntil = goal.daysUntilDeadline ?? 0;
        if (daysUntil > 0) {
          score += (365 - daysUntil) / 365 * 50; // Max 50 points for urgency
        }
      }
      
      // Completion percentage (higher score for goals closer to completion)
      score += goal.progressPercentage * 30; // Max 30 points for progress
      
      // Emergency fund gets priority boost
      if (goal.category.toLowerCase().contains('emergency')) {
        score += 20;
      }
      
      priority['score'] = score;
      priorities.add(priority);
    }
    
    // Sort by score (highest first)
    priorities.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    
    return priorities;
  }
}