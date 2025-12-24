import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/expense_predictor.dart';

/// Service for predicting budget exhaustion and assessing overspending risk
class BudgetPredictor {
  final ApiService _apiService = ApiService();
  final ExpensePredictor _expensePredictor = ExpensePredictor();

  /// Predict when a budget will be exhausted
  Future<Map<String, dynamic>> predictBudgetExhaustion({
    required String budgetId,
    required double budgetLimit,
    required double currentSpent,
  }) async {
    try {
      // Get recent transactions for this budget category
      final transactionsData = await _apiService.getTransactions(limit: 200);
      final transactions = List<dynamic>.from(
        transactionsData['transactions'] ?? [],
      );

      // Filter transactions for this budget's category
      // Note: This assumes we can match budget to category
      // You may need to adjust based on your budget model structure
      final categoryTransactions =
          transactions.where((t) {
            final type = t['type']?.toString().toLowerCase() ?? 'expense';
            return type == 'expense';
          }).toList();

      if (categoryTransactions.isEmpty) {
        return {
          'will_exhaust': false,
          'days_until_exhaustion': null,
          'risk_level': 'low',
          'message': 'Tidak ada data transaksi untuk prediksi',
        };
      }

      // Get expense forecast for next 30 days
      final forecast = await _expensePredictor.predictNext30Days(
        transactions:
            categoryTransactions.map((t) => t as Map<String, dynamic>).toList(),
      );

      final dailyForecast = (forecast['forecastAmount'] as double? ?? 0.0) / 30;
      final remainingBudget = budgetLimit - currentSpent;

      if (dailyForecast <= 0) {
        return {
          'will_exhaust': false,
          'days_until_exhaustion': null,
          'risk_level': 'low',
          'message': 'Prediksi pengeluaran harian terlalu rendah',
        };
      }

      final daysUntilExhaustion = remainingBudget / dailyForecast;
      final willExhaust = daysUntilExhaustion <= 30;

      // Calculate risk level
      String riskLevel;
      if (daysUntilExhaustion <= 7) {
        riskLevel = 'critical';
      } else if (daysUntilExhaustion <= 15) {
        riskLevel = 'high';
      } else if (daysUntilExhaustion <= 25) {
        riskLevel = 'medium';
      } else {
        riskLevel = 'low';
      }

      return {
        'will_exhaust': willExhaust,
        'days_until_exhaustion':
            willExhaust ? daysUntilExhaustion.round() : null,
        'risk_level': riskLevel,
        'daily_forecast': dailyForecast,
        'remaining_budget': remainingBudget,
        'exhaustion_date':
            willExhaust
                ? DateTime.now().add(
                  Duration(days: daysUntilExhaustion.round()),
                )
                : null,
        'message':
            willExhaust
                ? 'Budget diperkirakan habis dalam ${daysUntilExhaustion.round()} hari'
                : 'Budget aman untuk 30 hari ke depan',
      };
    } catch (e) {
      LoggerService.error('Error predicting budget exhaustion', error: e);
      return {
        'will_exhaust': false,
        'days_until_exhaustion': null,
        'risk_level': 'unknown',
        'message': 'Terjadi kesalahan saat memprediksi budget',
      };
    }
  }

  /// Assess overspending risk for all budgets
  Future<List<Map<String, dynamic>>> assessOverspendingRisk() async {
    try {
      final budgets = await _apiService.getBudgets();
      final riskAssessments = <Map<String, dynamic>>[];

      for (var budget in budgets) {
        final budgetMap = budget as Map<String, dynamic>;
        final budgetId = budgetMap['id']?.toString() ?? '';
        final budgetLimit = (budgetMap['amount'] as num?)?.toDouble() ?? 0.0;
        final currentSpent = (budgetMap['spent'] as num?)?.toDouble() ?? 0.0;
        final categoryName =
            budgetMap['category_name']?.toString() ?? 'Unknown';

        if (budgetLimit <= 0) continue;

        final exhaustionPrediction = await predictBudgetExhaustion(
          budgetId: budgetId,
          budgetLimit: budgetLimit,
          currentSpent: currentSpent,
        );

        final usagePercent = (currentSpent / budgetLimit) * 100;
        final remainingPercent = 100 - usagePercent;

        // Calculate overall risk score (0-100)
        double riskScore = 0.0;
        if (usagePercent >= 90) {
          riskScore = 90 + (usagePercent - 90); // 90-100
        } else if (usagePercent >= 75) {
          riskScore = 75 + ((usagePercent - 75) / 15) * 15; // 75-90
        } else if (usagePercent >= 50) {
          riskScore = 50 + ((usagePercent - 50) / 25) * 25; // 50-75
        } else {
          riskScore = usagePercent; // 0-50
        }

        // Adjust risk score based on exhaustion prediction
        final exhaustionRisk = exhaustionPrediction['risk_level'] as String?;
        if (exhaustionRisk == 'critical') {
          riskScore = (riskScore + 95) / 2; // Average with critical
        } else if (exhaustionRisk == 'high') {
          riskScore = (riskScore + 80) / 2;
        } else if (exhaustionRisk == 'medium') {
          riskScore = (riskScore + 60) / 2;
        }

        riskAssessments.add({
          'budget_id': budgetId,
          'category_name': categoryName,
          'budget_limit': budgetLimit,
          'current_spent': currentSpent,
          'remaining': budgetLimit - currentSpent,
          'usage_percent': usagePercent,
          'remaining_percent': remainingPercent,
          'risk_score': riskScore.clamp(0.0, 100.0),
          'risk_level': _getRiskLevelFromScore(riskScore),
          'exhaustion_prediction': exhaustionPrediction,
          'recommendation': _getRiskRecommendation(
            riskScore,
            usagePercent,
            exhaustionRisk,
          ),
        });
      }

      // Sort by risk score (highest first)
      riskAssessments.sort((a, b) {
        final scoreA = a['risk_score'] as double;
        final scoreB = b['risk_score'] as double;
        return scoreB.compareTo(scoreA);
      });

      return riskAssessments;
    } catch (e) {
      LoggerService.error('Error assessing overspending risk', error: e);
      return [];
    }
  }

  /// Get risk level from score
  String _getRiskLevelFromScore(double score) {
    if (score >= 80) return 'critical';
    if (score >= 60) return 'high';
    if (score >= 40) return 'medium';
    return 'low';
  }

  /// Get recommendation based on risk
  String _getRiskRecommendation(
    double riskScore,
    double usagePercent,
    String? exhaustionRisk,
  ) {
    if (riskScore >= 80 || exhaustionRisk == 'critical') {
      return 'Segera kurangi pengeluaran. Budget hampir habis!';
    } else if (riskScore >= 60 || exhaustionRisk == 'high') {
      return 'Perhatikan pengeluaran. Budget akan habis dalam waktu dekat.';
    } else if (riskScore >= 40 || exhaustionRisk == 'medium') {
      return 'Pantau pengeluaran dengan lebih hati-hati.';
    } else {
      return 'Budget masih aman. Lanjutkan pengelolaan yang baik.';
    }
  }

  /// Suggest optimal budget amounts based on historical patterns
  Future<Map<String, double>> suggestOptimalBudgets({
    int monthsToAnalyze = 3,
  }) async {
    try {
      final transactionsData = await _apiService.getTransactions(limit: 500);
      final transactions = List<dynamic>.from(
        transactionsData['transactions'] ?? [],
      );

      final now = DateTime.now();
      final categorySpending = <String, List<double>>{};

      // Analyze spending by category over the specified months
      for (int i = 0; i < monthsToAnalyze; i++) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final monthTransactions =
            transactions.where((t) {
              try {
                final dateStr =
                    t['transaction_date']?.toString() ??
                    t['date']?.toString() ??
                    '';
                if (dateStr.isEmpty) return false;
                final date = DateTime.parse(dateStr);
                final type = t['type']?.toString().toLowerCase() ?? 'expense';
                return date.year == monthDate.year &&
                    date.month == monthDate.month &&
                    type == 'expense';
              } catch (e) {
                return false;
              }
            }).toList();

        final monthlyCategoryTotals = <String, double>{};
        for (var t in monthTransactions) {
          final category = t['category_name']?.toString() ?? 'Lainnya';
          final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
          monthlyCategoryTotals[category] =
              (monthlyCategoryTotals[category] ?? 0) + amount;
        }

        monthlyCategoryTotals.forEach((category, amount) {
          categorySpending.putIfAbsent(category, () => []).add(amount);
        });
      }

      // Calculate optimal budget (average + 10% buffer)
      final optimalBudgets = <String, double>{};
      categorySpending.forEach((category, amounts) {
        if (amounts.isEmpty) return;

        final average = amounts.reduce((a, b) => a + b) / amounts.length;

        // Use average + 10% buffer, but cap at 1.5x average
        final optimal = (average * 1.1).clamp(average, average * 1.5);

        optimalBudgets[category] = optimal;
      });

      return optimalBudgets;
    } catch (e) {
      LoggerService.error('Error suggesting optimal budgets', error: e);
      return {};
    }
  }
}
