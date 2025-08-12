import '../models/savings_goal_model.dart';
import '../models/savings_settings_model.dart';
import 'savings_goal_service.dart';
import 'savings_settings_service.dart';

class SavingsTestData {
  static Future<void> createSampleData() async {
    // Create sample goals
    final emergencyFund = SavingsGoalModel(
      id: 'emergency_fund_001',
      name: 'Emergency Fund',
      targetAmount: 5000.0,
      currentAmount: 1250.0,
      category: 'Emergency',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      description: '6 months of expenses',
      iconName: 'emergency',
    );

    final vacation = SavingsGoalModel(
      id: 'vacation_001',
      name: 'Summer Vacation',
      targetAmount: 2500.0,
      currentAmount: 800.0,
      deadline: DateTime.now().add(const Duration(days: 120)),
      category: 'Travel',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      description: 'Trip to Europe',
      iconName: 'travel',
    );

    final carFund = SavingsGoalModel(
      id: 'car_fund_001',
      name: 'New Car',
      targetAmount: 15000.0,
      currentAmount: 3500.0,
      deadline: DateTime.now().add(const Duration(days: 365)),
      category: 'Transportation',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      description: 'Down payment for new car',
      iconName: 'car',
    );

    await SavingsGoalService.createGoal(emergencyFund);
    await SavingsGoalService.createGoal(vacation);
    await SavingsGoalService.createGoal(carFund);

    // Set up default settings
    final settings = SavingsSettingsModel(
      roundUpEnabled: true,
      roundUpGoalId: 'emergency_fund_001',
      roundUpMultiplier: 2.0,
      autoSaveEnabled: true,
      autoSavePercentage: 0.15,
      notificationsEnabled: true,
      goalMilestoneNotifications: true,
      weeklyProgressNotifications: false,
    );

    await SavingsSettingsService.update(settings);
  }

  static Future<void> clearAllData() async {
    // Clear all savings goals
    final goals = SavingsGoalService.getAllWithKeys();
    for (final entry in goals) {
      await SavingsGoalService.deleteGoal(entry.value.id);
    }

    // Reset settings to defaults
    await SavingsSettingsService.resetToDefaults();
  }
}