import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/notification_service.dart';

/// Service untuk budget forecasting dan analytics
class BudgetForecastService {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();

  /// Calculate budget forecast berdasarkan spending pattern
  Future<Map<String, dynamic>> calculateForecast({
    required String budgetId,
    required double currentSpent,
    required double budgetAmount,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final now = DateTime.now();
      final daysElapsed = now.difference(startDate).inDays;
      final totalDays = endDate.difference(startDate).inDays;

      if (daysElapsed <= 0 || totalDays <= 0) {
        return {
          'forecastedSpent': currentSpent,
          'forecastedPercentage': 0.0,
          'isOverBudget': false,
          'daysRemaining': totalDays,
        };
      }

      // Calculate average daily spending
      final averageDailySpending = currentSpent / daysElapsed;

      // Forecast untuk sisa hari
      final daysRemaining = endDate.difference(now).inDays;
      final forecastedRemaining = averageDailySpending * daysRemaining;
      final forecastedSpent = currentSpent + forecastedRemaining;

      // Calculate percentage
      final forecastedPercentage = (forecastedSpent / budgetAmount) * 100;
      final isOverBudget = forecastedSpent > budgetAmount;

      // Calculate trend (increasing, decreasing, stable)
      String trend = 'stable';
      if (daysElapsed >= 7) {
        // Get spending pattern dari last 7 days vs first 7 days
        final recentSpending = await _getRecentSpendingPattern(budgetId, 7);
        final earlySpending = await _getEarlySpendingPattern(budgetId, 7);

        if (recentSpending > earlySpending * 1.2) {
          trend = 'increasing';
        } else if (recentSpending < earlySpending * 0.8) {
          trend = 'decreasing';
        }
      }

      return {
        'forecastedSpent': forecastedSpent,
        'forecastedPercentage': forecastedPercentage,
        'isOverBudget': isOverBudget,
        'daysRemaining': daysRemaining,
        'averageDailySpending': averageDailySpending,
        'trend': trend,
        'projectedOverspend':
            isOverBudget ? forecastedSpent - budgetAmount : 0.0,
      };
    } catch (e) {
      LoggerService.error('Error calculating forecast', error: e);
      return {
        'forecastedSpent': currentSpent,
        'forecastedPercentage': 0.0,
        'isOverBudget': false,
        'daysRemaining': 0,
      };
    }
  }

  /// Get recent spending pattern
  Future<double> _getRecentSpendingPattern(String budgetId, int days) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      // Get transactions untuk budget category
      final transactionsData = await _apiService.getTransactions(
        startDate: startDate,
        endDate: endDate,
        limit: 1000,
      );
      final transactions = List<dynamic>.from(
        transactionsData['transactions'] ?? [],
      );

      // Filter by budget category dan sum
      // Note: Ini perlu disesuaikan dengan struktur data budget
      double total = 0.0;
      for (var transaction in transactions) {
        if (transaction['type'] == 'expense') {
          total += (transaction['amount'] as num?)?.toDouble() ?? 0.0;
        }
      }

      return total;
    } catch (e) {
      LoggerService.error('Error getting recent spending pattern', error: e);
      return 0.0;
    }
  }

  /// Get early spending pattern
  Future<double> _getEarlySpendingPattern(String budgetId, int days) async {
    try {
      final now = DateTime.now();
      final endDate = now.subtract(Duration(days: now.day - 1));
      final startDate = endDate.subtract(Duration(days: days));

      if (startDate.isBefore(endDate)) {
        final transactionsData = await _apiService.getTransactions(
          startDate: startDate,
          endDate: endDate,
          limit: 1000,
        );
        final transactions = List<dynamic>.from(
          transactionsData['transactions'] ?? [],
        );

        double total = 0.0;
        for (var transaction in transactions) {
          if (transaction['type'] == 'expense') {
            total += (transaction['amount'] as num?)?.toDouble() ?? 0.0;
          }
        }

        return total;
      }

      return 0.0;
    } catch (e) {
      LoggerService.error('Error getting early spending pattern', error: e);
      return 0.0;
    }
  }

  /// Check dan send budget alerts
  Future<void> checkAndSendBudgetAlerts() async {
    try {
      final budgets = await _apiService.getBudgets(activeOnly: true);

      for (var budget in budgets) {
        final budgetMap = budget as Map<String, dynamic>;
        final spent = (budgetMap['spent'] as num?)?.toDouble() ?? 0.0;
        final amount = (budgetMap['amount'] as num?)?.toDouble() ?? 0.0;
        final percentage = amount > 0 ? (spent / amount) * 100 : 0.0;

        // Alert at 80%
        if (percentage >= 80 && percentage < 90) {
          await _sendBudgetAlert(budgetMap, 'warning', 'Budget mencapai 80%');
        }

        // Alert at 90%
        if (percentage >= 90 && percentage < 100) {
          await _sendBudgetAlert(budgetMap, 'critical', 'Budget hampir habis!');
        }

        // Alert when over budget
        if (spent > amount) {
          await _sendBudgetAlert(budgetMap, 'over', 'Budget terlampaui!');
        }
      }
    } catch (e) {
      LoggerService.error('Error checking budget alerts', error: e);
    }
  }

  /// Send budget alert notification
  Future<void> _sendBudgetAlert(
    Map<String, dynamic> budget,
    String level,
    String title,
  ) async {
    try {
      final categoryId = budget['category_id'] as String?;
      final spent = (budget['spent'] as num?)?.toDouble() ?? 0.0;
      final amount = (budget['amount'] as num?)?.toDouble() ?? 0.0;
      final percentage = amount > 0 ? (spent / amount) * 100 : 0.0;

      String emoji = '⚠️';
      if (level == 'critical') emoji = '🔴';
      if (level == 'over') emoji = '🚨';

      final body =
          'Pengeluaran: ${spent.toStringAsFixed(0)} dari ${amount.toStringAsFixed(0)} (${percentage.toStringAsFixed(0)}%)';

      await _notificationService.showNotification(
        id: 'budget_${categoryId}_${level}'.hashCode,
        title: '$emoji $title',
        body: body,
        priority:
            level == 'over'
                ? NotificationPriority.high
                : NotificationPriority.medium,
        payload: 'budget:$categoryId',
      );
    } catch (e) {
      LoggerService.error('Error sending budget alert', error: e);
    }
  }

  /// Get budget history trends
  Future<List<Map<String, dynamic>>> getBudgetHistoryTrends({
    required String categoryId,
    int months = 6,
  }) async {
    try {
      final trends = <Map<String, dynamic>>[];
      final now = DateTime.now();

      for (int i = months - 1; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);

        // Get budget untuk bulan ini
        final budgets = await _apiService.getBudgets(activeOnly: false);

        // Find budget untuk category
        final budget = budgets.firstWhere((b) {
          final budgetMap = b as Map<String, dynamic>;
          return budgetMap['category_id']?.toString() == categoryId;
        }, orElse: () => <String, dynamic>{});

        if (budget.isNotEmpty) {
          final budgetMap = budget as Map<String, dynamic>;
          trends.add({
            'month': monthDate.month,
            'year': monthDate.year,
            'spent': (budgetMap['spent'] as num?)?.toDouble() ?? 0.0,
            'amount': (budgetMap['amount'] as num?)?.toDouble() ?? 0.0,
            'percentage':
                (budgetMap['amount'] as num?)?.toDouble() != null &&
                        (budgetMap['amount'] as num?)!.toDouble() > 0
                    ? (((budgetMap['spent'] as num?)?.toDouble() ?? 0.0) /
                            (budgetMap['amount'] as num?)!.toDouble()) *
                        100
                    : 0.0,
          });
        }
      }

      return trends;
    } catch (e) {
      LoggerService.error('Error getting budget history trends', error: e);
      return [];
    }
  }

  /// Group budgets by category
  Map<String, List<Map<String, dynamic>>> groupBudgetsByCategory(
    List<Map<String, dynamic>> budgets,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (var budget in budgets) {
      final categoryId = budget['category_id'] as String? ?? 'all';
      if (!grouped.containsKey(categoryId)) {
        grouped[categoryId] = [];
      }
      grouped[categoryId]!.add(budget);
    }

    return grouped;
  }
}
