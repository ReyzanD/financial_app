import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/logger_service.dart';

/// Enhanced AI Recommendations Service dengan personalization, pattern analysis, dan savings opportunities
class AIRecommendationsEnhancedService {
  final ApiService _apiService = ApiService();

  /// Generate personalized recommendations
  Future<List<Map<String, dynamic>>>
  generatePersonalizedRecommendations() async {
    try {
      final transactions = await _apiService.getTransactions(limit: 200);
      final budgets = await _apiService.getBudgets();
      final goals = await _apiService.getGoals();

      final recommendations = <Map<String, dynamic>>[];

      // 1. Spending pattern analysis
      final patternAnalysis = _analyzeSpendingPatterns(
        transactions as List<dynamic>,
      );
      recommendations.addAll(_generatePatternRecommendations(patternAnalysis));

      // 2. Savings opportunities
      final savingsOps = _identifySavingsOpportunities(
        transactions as List<dynamic>,
        budgets,
      );
      recommendations.addAll(savingsOps);

      // 3. Bill optimization
      final billOpts = _suggestBillOptimizations(transactions as List<dynamic>);
      recommendations.addAll(billOpts);

      // 4. Financial goal recommendations
      final goalRecs = _recommendFinancialGoals(
        transactions as List<dynamic>,
        goals,
      );
      recommendations.addAll(goalRecs);

      // Sort by priority/impact
      recommendations.sort((a, b) {
        final priorityA = (a['priority'] as num?)?.toInt() ?? 0;
        final priorityB = (b['priority'] as num?)?.toInt() ?? 0;
        return priorityB.compareTo(priorityA);
      });

      return recommendations.take(5).toList();
    } catch (e) {
      LoggerService.error(
        'Error generating personalized recommendations',
        error: e,
      );
      return [];
    }
  }

  Map<String, dynamic> _analyzeSpendingPatterns(List<dynamic> transactions) {
    final now = DateTime.now();
    final thisMonth =
        transactions.where((t) {
          try {
            final dateStr =
                t['transaction_date']?.toString() ??
                t['date']?.toString() ??
                '';
            if (dateStr.isEmpty) return false;
            final date = DateTime.parse(dateStr);
            return date.month == now.month && date.year == now.year;
          } catch (e) {
            return false;
          }
        }).toList();

    final lastMonth =
        transactions.where((t) {
          try {
            final dateStr =
                t['transaction_date']?.toString() ??
                t['date']?.toString() ??
                '';
            if (dateStr.isEmpty) return false;
            final date = DateTime.parse(dateStr);
            final lastMonthDate = DateTime(now.year, now.month - 1);
            return date.month == lastMonthDate.month &&
                date.year == lastMonthDate.year;
          } catch (e) {
            return false;
          }
        }).toList();

    double thisMonthExpense = 0;
    double lastMonthExpense = 0;
    Map<String, double> categorySpending = {};
    Map<String, int> categoryFrequency = {};

    for (var t in thisMonth) {
      final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
      final type = t['type']?.toString().toLowerCase() ?? 'expense';
      final category = t['category_name']?.toString() ?? 'Lainnya';

      if (type == 'expense') {
        thisMonthExpense += amount;
        categorySpending[category] = (categorySpending[category] ?? 0) + amount;
        categoryFrequency[category] = (categoryFrequency[category] ?? 0) + 1;
      }
    }

    for (var t in lastMonth) {
      final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
      final type = t['type']?.toString().toLowerCase() ?? 'expense';
      if (type == 'expense') {
        lastMonthExpense += amount;
      }
    }

    // Find top spending category
    String? topCategory;
    double topAmount = 0;
    categorySpending.forEach((cat, amt) {
      if (amt > topAmount) {
        topAmount = amt;
        topCategory = cat;
      }
    });

    return {
      'this_month_expense': thisMonthExpense,
      'last_month_expense': lastMonthExpense,
      'change_percentage':
          lastMonthExpense > 0
              ? ((thisMonthExpense - lastMonthExpense) / lastMonthExpense) * 100
              : 0.0,
      'top_category': topCategory,
      'top_category_amount': topAmount,
      'category_spending': categorySpending,
      'category_frequency': categoryFrequency,
    };
  }

  List<Map<String, dynamic>> _generatePatternRecommendations(
    Map<String, dynamic> analysis,
  ) {
    final recommendations = <Map<String, dynamic>>[];

    final changePercentage = analysis['change_percentage'] as double;
    final topCategory = analysis['top_category'] as String?;
    final topAmount = analysis['top_category_amount'] as double;

    // Spending increase alert
    if (changePercentage > 20) {
      recommendations.add({
        'type': 'spending_increase',
        'title': 'Pengeluaran Meningkat',
        'message':
            'Pengeluaran bulan ini meningkat ${changePercentage.toStringAsFixed(0)}% dari bulan lalu. Pertimbangkan untuk mengurangi pengeluaran.',
        'priority': 8,
        'icon': 'warning',
        'action': 'review_budget',
      });
    }

    // Top category recommendation
    if (topCategory != null && topAmount > 0) {
      recommendations.add({
        'type': 'top_category',
        'title': 'Kategori Terbesar',
        'message':
            '$topCategory adalah kategori pengeluaran terbesar Anda (${topAmount.toStringAsFixed(0)}). Pertimbangkan untuk membuat budget khusus.',
        'priority': 7,
        'icon': 'category',
        'action': 'create_budget',
        'category': topCategory,
      });
    }

    return recommendations;
  }

  List<Map<String, dynamic>> _identifySavingsOpportunities(
    List<dynamic> transactions,
    List<dynamic> budgets,
  ) {
    final recommendations = <Map<String, dynamic>>[];

    // Analyze recurring expenses
    final recurringExpenses = <String, List<Map<String, dynamic>>>{};
    for (var t in transactions) {
      final description = (t['description'] ?? '').toString().toLowerCase();
      final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
      final type = t['type']?.toString().toLowerCase() ?? 'expense';

      if (type == 'expense' && amount > 0) {
        // Check for subscription-like patterns
        if (description.contains('netflix') ||
            description.contains('spotify') ||
            description.contains('subscription') ||
            description.contains('langganan')) {
          final key = description;
          recurringExpenses[key] ??= [];
          recurringExpenses[key]!.add({
            'amount': amount,
            'date': t['transaction_date'] ?? t['date'],
          });
        }
      }
    }

    // Suggest canceling unused subscriptions
    for (var entry in recurringExpenses.entries) {
      if (entry.value.length == 1) {
        // Only one transaction, might be unused
        recommendations.add({
          'type': 'unused_subscription',
          'title': 'Langganan Tidak Terpakai?',
          'message':
              'Anda memiliki langganan yang mungkin tidak terpakai. Pertimbangkan untuk membatalkannya dan hemat ${entry.value[0]['amount']} per bulan.',
          'priority': 6,
          'icon': 'subscription',
          'action': 'review_subscriptions',
          'amount': entry.value[0]['amount'],
        });
      }
    }

    // Budget vs actual savings opportunity
    for (var budget in budgets) {
      final budgetMap = budget as Map<String, dynamic>;
      final spent = (budgetMap['spent'] as num?)?.toDouble() ?? 0.0;
      final amount = (budgetMap['amount'] as num?)?.toDouble() ?? 0.0;

      if (amount > 0 && spent < amount * 0.5) {
        // Spending less than 50% of budget
        final potentialSavings = amount - spent;
        recommendations.add({
          'type': 'under_budget',
          'title': 'Peluang Menabung',
          'message':
              'Anda berada di bawah budget. Anda bisa menabung ${potentialSavings.toStringAsFixed(0)} lebih banyak.',
          'priority': 5,
          'icon': 'savings',
          'action': 'adjust_budget',
          'savings': potentialSavings,
        });
      }
    }

    return recommendations;
  }

  List<Map<String, dynamic>> _suggestBillOptimizations(
    List<dynamic> transactions,
  ) {
    final recommendations = <Map<String, dynamic>>[];

    // Group similar bills
    final billPatterns = <String, List<Map<String, dynamic>>>{};
    for (var t in transactions) {
      final description = (t['description'] ?? '').toString().toLowerCase();
      final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
      final type = t['type']?.toString().toLowerCase() ?? 'expense';

      if (type == 'expense' && amount > 50000) {
        // Large expenses might be bills
        if (description.contains('listrik') ||
            description.contains('air') ||
            description.contains('internet') ||
            description.contains('telepon')) {
          final category = description;
          billPatterns[category] ??= [];
          billPatterns[category]!.add({
            'amount': amount,
            'date': t['transaction_date'] ?? t['date'],
          });
        }
      }
    }

    // Suggest optimizations
    for (var entry in billPatterns.entries) {
      if (entry.value.length >= 2) {
        // Multiple bills, check for increases
        final amounts = entry.value.map((e) => e['amount'] as double).toList();
        amounts.sort();
        final avgAmount = amounts.reduce((a, b) => a + b) / amounts.length;
        final maxAmount = amounts.last;

        if (maxAmount > avgAmount * 1.2) {
          // Significant increase
          recommendations.add({
            'type': 'bill_increase',
            'title': 'Tagihan Meningkat',
            'message':
                'Tagihan ${entry.key} meningkat. Pertimbangkan untuk memeriksa penggunaan atau mencari provider alternatif.',
            'priority': 7,
            'icon': 'bill',
            'action': 'review_bills',
            'category': entry.key,
          });
        }
      }
    }

    return recommendations;
  }

  List<Map<String, dynamic>> _recommendFinancialGoals(
    List<dynamic> transactions,
    List<dynamic> goals,
  ) {
    final recommendations = <Map<String, dynamic>>[];

    // Calculate savings rate
    double totalIncome = 0;
    double totalExpense = 0;
    for (var t in transactions) {
      final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
      final type = t['type']?.toString().toLowerCase() ?? 'expense';
      if (type == 'income') {
        totalIncome += amount;
      } else if (type == 'expense') {
        totalExpense += amount;
      }
    }

    final savingsRate =
        totalIncome > 0
            ? ((totalIncome - totalExpense) / totalIncome) * 100
            : 0.0;

    // Recommend emergency fund if no goals
    if (goals.isEmpty && savingsRate > 10) {
      final monthlySavings = (totalIncome - totalExpense) / 12;
      final emergencyFundTarget = monthlySavings * 6; // 6 months

      recommendations.add({
        'type': 'emergency_fund',
        'title': 'Dana Darurat',
        'message':
            'Berdasarkan pengeluaran Anda, disarankan untuk memiliki dana darurat sebesar ${emergencyFundTarget.toStringAsFixed(0)} (6 bulan pengeluaran).',
        'priority': 9,
        'icon': 'goal',
        'action': 'create_goal',
        'target': emergencyFundTarget,
      });
    }

    // Recommend savings goal if savings rate is good
    if (savingsRate > 20 && goals.length < 3) {
      recommendations.add({
        'type': 'savings_goal',
        'title': 'Tujuan Menabung',
        'message':
            'Tingkat tabungan Anda bagus (${savingsRate.toStringAsFixed(0)}%). Pertimbangkan untuk membuat tujuan menabung jangka panjang.',
        'priority': 6,
        'icon': 'goal',
        'action': 'create_goal',
      });
    }

    return recommendations;
  }
}
