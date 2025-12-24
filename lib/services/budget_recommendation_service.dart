import 'package:flutter/material.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/budget_predictor.dart';
import 'package:financial_app/services/spending_pattern_analyzer.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// Service untuk generate AI budget recommendations with dynamic allocation
class BudgetRecommendationService {
  final ApiService _apiService = ApiService();
  final BudgetPredictor _budgetPredictor = BudgetPredictor();
  final SpendingPatternAnalyzer _patternAnalyzer = SpendingPatternAnalyzer();

  /// Generate budget recommendation berdasarkan income dan recurring expenses
  Future<Map<String, dynamic>> generateRecommendation() async {
    try {
      // Get financial summary
      final summary = await _apiService.getFinancialSummary();
      final summaries = summary['summary'] as Map<String, dynamic>?;

      if (summaries == null) {
        throw Exception('Tidak ada data keuangan tersedia');
      }

      final income =
          (summaries['income'] as Map<String, dynamic>?)?['total_amount'] ??
          0.0;

      // Get recurring transactions and bills (with error handling)
      double monthlyRecurringExpenses = 0.0;

      try {
        final recurringTransactions =
            await _apiService.getRecurringTransactions();
        // Sum recurring transactions
        for (var recurring in recurringTransactions) {
          if (recurring['type'] == 'expense' &&
              recurring['is_active'] == true) {
            final amount = (recurring['amount'] ?? 0.0).toDouble();
            monthlyRecurringExpenses += amount;
          }
        }
      } catch (e) {
        LoggerService.warning(
          'Could not fetch recurring transactions',
          error: e,
        );
      }

      try {
        final bills = await _apiService.getObligations();
        // Sum bills/obligations
        for (var bill in bills) {
          if (bill['status_232143'] == 'active') {
            final monthlyAmountRaw = bill['monthly_amount_232143'];
            final amount =
                monthlyAmountRaw is num
                    ? monthlyAmountRaw.toDouble()
                    : (double.tryParse(monthlyAmountRaw?.toString() ?? '0') ??
                        0.0);
            monthlyRecurringExpenses += amount;
          }
        }
      } catch (e) {
        LoggerService.warning('Could not fetch obligations', error: e);
      }

      // Get historical spending data for dynamic allocation
      final transactionsData = await _apiService.getTransactions(limit: 500);
      final transactions =
          transactionsData['transactions'] as List<dynamic>? ?? [];

      // Get goals for goal-aligned allocation
      final goals = await _apiService.getGoals();

      // Generate dynamic budget recommendation based on historical data
      return await _generateDynamicBudgetRecommendation(
        income,
        monthlyRecurringExpenses,
        transactions,
        goals,
      );
    } catch (e) {
      LoggerService.error('Error generating budget recommendation', error: e);
      rethrow;
    }
  }

  /// Generate dynamic budget recommendation based on historical spending patterns
  Future<Map<String, dynamic>> _generateDynamicBudgetRecommendation(
    double income,
    double monthlyRecurringExpenses,
    List<dynamic> transactions,
    List<dynamic> goals,
  ) async {
    // Check if user is new (no transactions or very few transactions)
    final isNewUser = transactions.isEmpty;
    final hasVeryFewTransactions = transactions.length < 3;
    
    // Count expense transactions
    final expenseTransactions = transactions.where((t) {
      final type = t['type']?.toString().toLowerCase() ?? '';
      return type == 'expense';
    }).toList();
    
    final hasNoExpenseTransactions = expenseTransactions.isEmpty;
    
    // If new user or very few transactions or no expense transactions, use template
    if (isNewUser || hasVeryFewTransactions || hasNoExpenseTransactions) {
      LoggerService.debug(
        'Using template budget: isNewUser=$isNewUser, '
        'hasVeryFewTransactions=$hasVeryFewTransactions, '
        'hasNoExpenseTransactions=$hasNoExpenseTransactions',
      );
      return await _generateTemplateBudgetRecommendation(
        income,
        monthlyRecurringExpenses,
        goals,
      );
    }
    
    // Analyze 3-6 months of historical spending
    final multiPeriodAnalysis = _patternAnalyzer.analyzeMultiPeriod(
      transactions: transactions,
      monthsToAnalyze: 6, // Use 6 months for better accuracy
    );

    final periodData =
        multiPeriodAnalysis['period_data'] as Map<String, dynamic>? ?? {};
    final trends = multiPeriodAnalysis['trends'] as Map<String, dynamic>? ?? {};
    
    // Check if periodData is empty (no spending history)
    if (periodData.isEmpty) {
      LoggerService.debug('Period data is empty, using template budget');
      return await _generateTemplateBudgetRecommendation(
        income,
        monthlyRecurringExpenses,
        goals,
      );
    }

    // Calculate average monthly spending by category
    final categoryAverages = <String, double>{};
    final categoryPercentages = <String, double>{};
    double totalAverageExpense = 0.0;

    // Aggregate category spending across all months
    for (var monthData in periodData.values) {
      final monthMap = monthData as Map<String, dynamic>;
      final catSpending =
          monthMap['category_spending'] as Map<String, double>? ?? {};
      final monthExpense = monthMap['expense'] as double? ?? 0.0;
      totalAverageExpense += monthExpense;

      catSpending.forEach((category, amount) {
        categoryAverages[category] = (categoryAverages[category] ?? 0) + amount;
      });
    }

    // Calculate average per month
    final monthsCount = periodData.length > 0 ? periodData.length : 1;
    totalAverageExpense = totalAverageExpense / monthsCount;
    categoryAverages.forEach((category, total) {
      categoryAverages[category] = total / monthsCount;
      if (totalAverageExpense > 0) {
        categoryPercentages[category] =
            (categoryAverages[category]! / totalAverageExpense) * 100;
      }
    });

    // Check if user has no expenses at all (only income transactions)
    final hasNoExpenses = totalAverageExpense == 0.0 && categoryAverages.isEmpty;
    
    // If user has transactions but no expenses, use template with income-based allocation
    if (hasNoExpenses) {
      LoggerService.debug(
        'User has transactions but no expenses, using template budget',
      );
      return await _generateTemplateBudgetRecommendation(
        income,
        monthlyRecurringExpenses,
        goals,
      );
    }

    // Calculate available income after recurring expenses
    final availableIncome = income - monthlyRecurringExpenses;
    final recurringPercentage =
        income > 0 ? (monthlyRecurringExpenses / income) * 100 : 0;

    // Get optimal budget suggestions from BudgetPredictor
    final optimalBudgets = await _budgetPredictor.suggestOptimalBudgets(
      monthsToAnalyze: 6,
    );
    
    // Check if optimalBudgets is empty (no spending patterns detected)
    final hasNoSpendingPatterns = optimalBudgets.isEmpty && categoryAverages.isEmpty;
    
    // If no spending patterns detected, use template
    if (hasNoSpendingPatterns) {
      LoggerService.debug(
        'No spending patterns detected, using template budget',
      );
      return await _generateTemplateBudgetRecommendation(
        income,
        monthlyRecurringExpenses,
        goals,
      );
    }

    // Calculate flexibility scores (which categories can be adjusted)
    final flexibilityScores = _calculateFlexibilityScores(
      categoryAverages,
      monthlyRecurringExpenses,
    );

    // Goal-aligned allocation adjustments
    final goalAdjustments = _calculateGoalAdjustments(
      goals,
      income,
      totalAverageExpense,
    );

    // Build dynamic category recommendations
    final recommendedCategories = <Map<String, dynamic>>[];

    // 1. Recurring Bills & Subscriptions (fixed)
    if (monthlyRecurringExpenses > 0) {
      recommendedCategories.add({
        'name': 'Tagihan & Langganan Rutin',
        'percentage': recurringPercentage,
        'amount': monthlyRecurringExpenses,
        'icon': Iconsax.receipt_2,
        'color': const Color(0xFFFF5252),
        'description': '⚡ Dari tagihan & langganan Anda yang aktif',
        'flexibility': 'fixed', // Cannot be adjusted
        'is_recurring': true,
      });
    }

    // 2. Dynamic category allocations based on historical data
    final essentialCategories = [
      'Makanan',
      'Transportasi',
      'Kebutuhan Pokok',
      'Tagihan',
    ];
    final discretionaryCategories = [
      'Hiburan',
      'Shopping',
      'Hobi',
      'Lifestyle',
    ];

    // Essential needs (based on historical average + 10% buffer)
    double essentialTotal = 0.0;
    for (var category in essentialCategories) {
      final avgSpending = categoryAverages[category] ?? 0.0;
      final optimal = optimalBudgets[category] ?? (avgSpending * 1.1);
      if (optimal > 0) {
        essentialTotal += optimal;
        final percentage = income > 0 ? (optimal / income) * 100 : 0;
        recommendedCategories.add({
          'name': category,
          'percentage': percentage,
          'amount': optimal,
          'icon': _getCategoryIcon(category),
          'color': _getCategoryColor(category),
          'description': 'Berdasarkan rata-rata pengeluaran 6 bulan terakhir',
          'flexibility': flexibilityScores[category] ?? 'moderate',
          'historical_average': avgSpending,
          'recommended': optimal,
        });
      }
    }

    // Discretionary spending (based on historical patterns)
    double discretionaryTotal = 0.0;
    for (var category in discretionaryCategories) {
      final avgSpending = categoryAverages[category] ?? 0.0;
      if (avgSpending > 0) {
        final optimal =
            optimalBudgets[category] ?? (avgSpending * 1.05); // 5% buffer
        discretionaryTotal += optimal;
        final percentage = income > 0 ? (optimal / income) * 100 : 0;
        recommendedCategories.add({
          'name': category,
          'percentage': percentage,
          'amount': optimal,
          'icon': _getCategoryIcon(category),
          'color': _getCategoryColor(category),
          'description': 'Disesuaikan dengan pola pengeluaran Anda',
          'flexibility': 'high', // Can be easily adjusted
          'historical_average': avgSpending,
          'recommended': optimal,
        });
      }
    }

    // Savings & Investments (goal-aligned)
    final savingsRate =
        income > 0 ? ((income - totalAverageExpense) / income) * 100 : 0;
    final targetSavingsRate =
        savingsRate < 10
            ? 15.0
            : savingsRate < 20
            ? 20.0
            : 25.0;
    final savingsAmount = income * (targetSavingsRate / 100);

    // Adjust savings based on goals
    final goalSavingsAdjustment = goalAdjustments['savings'] as double? ?? 0.0;
    final finalSavingsAmount = savingsAmount + goalSavingsAdjustment;
    final savingsPercentage =
        income > 0 ? (finalSavingsAmount / income) * 100 : 0;

    recommendedCategories.add({
      'name': 'Tabungan & Investasi',
      'percentage': savingsPercentage,
      'amount': finalSavingsAmount,
      'icon': Iconsax.chart,
      'color': const Color(0xFF2196F3),
      'description':
          'Target: ${targetSavingsRate.toStringAsFixed(0)}% dari pendapatan (${goalAdjustments['savings_reason'] ?? 'sesuai pola pengeluaran'})',
      'flexibility': 'low', // Should maintain minimum
      'target_rate': targetSavingsRate,
      'goal_adjusted': goalSavingsAdjustment > 0,
    });

    // Emergency Fund (if not already covered by goals)
    final hasEmergencyFundGoal = goals.any(
      (g) =>
          (g['type']?.toString().toLowerCase() ?? '').contains('emergency') ||
          (g['name']?.toString().toLowerCase() ?? '').contains('darurat'),
    );

    if (!hasEmergencyFundGoal && savingsPercentage < 15) {
      final emergencyAmount = income * 0.10;
      recommendedCategories.add({
        'name': 'Dana Darurat',
        'percentage': 10.0,
        'amount': emergencyAmount,
        'icon': Iconsax.shield_tick,
        'color': const Color(0xFFFF9800),
        'description': 'Target: 6 bulan pengeluaran',
        'flexibility': 'low',
      });
    }

    // Calculate total allocated
    double totalAllocated =
        monthlyRecurringExpenses +
        essentialTotal +
        discretionaryTotal +
        finalSavingsAmount;
    final remainingIncome = income - totalAllocated;

    // If there's remaining income, allocate to highest priority category
    if (remainingIncome > 0 && remainingIncome < income * 0.05) {
      // Small remainder, add to savings
      final savingsIndex = recommendedCategories.indexWhere(
        (c) => c['name'] == 'Tabungan & Investasi',
      );
      if (savingsIndex >= 0) {
        recommendedCategories[savingsIndex]['amount'] =
            (recommendedCategories[savingsIndex]['amount'] as double) +
            remainingIncome;
        recommendedCategories[savingsIndex]['percentage'] =
            income > 0
                ? ((recommendedCategories[savingsIndex]['amount'] as double) /
                        income) *
                    100
                : 0;
      }
    }

    return {
      'total_income': income,
      'monthly_recurring_expenses': monthlyRecurringExpenses,
      'available_income': availableIncome,
      'categories': recommendedCategories,
      'allocation_method': 'dynamic', // Indicates this is dynamic allocation
      'months_analyzed': monthsCount,
      'historical_average_expense': totalAverageExpense,
      'recommended_savings_rate': targetSavingsRate,
      'trends': trends,
      'flexibility_scores': flexibilityScores,
    };
  }

  /// Calculate flexibility scores for categories
  Map<String, String> _calculateFlexibilityScores(
    Map<String, double> categoryAverages,
    double recurringExpenses,
  ) {
    final scores = <String, String>{};

    // Fixed expenses (cannot be adjusted)
    final fixedCategories = ['Tagihan', 'Cicilan', 'Hutang'];
    fixedCategories.forEach((cat) {
      scores[cat] = 'fixed';
    });

    // Essential but adjustable
    final essentialCategories = ['Makanan', 'Transportasi', 'Kebutuhan Pokok'];
    essentialCategories.forEach((cat) {
      scores[cat] = 'moderate';
    });

    // Highly flexible
    final flexibleCategories = ['Hiburan', 'Shopping', 'Hobi', 'Lifestyle'];
    flexibleCategories.forEach((cat) {
      scores[cat] = 'high';
    });

    return scores;
  }

  /// Calculate goal-aligned allocation adjustments
  Map<String, dynamic> _calculateGoalAdjustments(
    List<dynamic> goals,
    double income,
    double averageExpense,
  ) {
    final adjustments = <String, dynamic>{};
    double savingsAdjustment = 0.0;
    String? savingsReason;

    for (var goal in goals) {
      final goalType =
          (goal['type']?.toString().toLowerCase() ?? '').toLowerCase();
      final targetAmount = (goal['target_amount'] as num?)?.toDouble() ?? 0.0;
      final currentAmount = (goal['current_amount'] as num?)?.toDouble() ?? 0.0;
      final remaining = targetAmount - currentAmount;

      if (goalType.contains('emergency') || goalType.contains('darurat')) {
        // Emergency fund goal
        final monthlyContribution = remaining / 12; // 12 months to reach goal
        savingsAdjustment += monthlyContribution;
        savingsReason = 'untuk mencapai dana darurat';
      } else if (goalType.contains('savings') ||
          goalType.contains('tabungan')) {
        // General savings goal
        final monthlyContribution = remaining / 24; // 24 months to reach goal
        savingsAdjustment += monthlyContribution;
        savingsReason = 'untuk mencapai tujuan tabungan';
      } else if (goalType.contains('investment') ||
          goalType.contains('investasi')) {
        // Investment goal
        final monthlyContribution = remaining / 36; // 36 months to reach goal
        savingsAdjustment += monthlyContribution;
        savingsReason = 'untuk mencapai tujuan investasi';
      }
    }

    adjustments['savings'] = savingsAdjustment;
    adjustments['savings_reason'] = savingsReason;
    adjustments['goals_count'] = goals.length;

    return adjustments;
  }

  /// Get icon for category
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'makanan':
        return Iconsax.cake;
      case 'transportasi':
        return Iconsax.car;
      case 'hiburan':
        return Iconsax.music;
      case 'shopping':
        return Iconsax.shopping_bag;
      case 'hobi':
        return Iconsax.game;
      case 'tabungan':
      case 'investasi':
        return Iconsax.chart;
      case 'dana darurat':
        return Iconsax.shield_tick;
      default:
        return Iconsax.wallet;
    }
  }

  /// Get color for category
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'makanan':
        return const Color(0xFF4CAF50);
      case 'transportasi':
        return const Color(0xFF2196F3);
      case 'hiburan':
        return const Color(0xFFE91E63);
      case 'shopping':
        return const Color(0xFF9C27B0);
      case 'hobi':
        return const Color(0xFFFF9800);
      case 'tabungan':
      case 'investasi':
        return const Color(0xFF2196F3);
      case 'dana darurat':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF757575);
    }
  }

  /// Generate template budget recommendation for new users
  Future<Map<String, dynamic>> _generateTemplateBudgetRecommendation(
    double income,
    double monthlyRecurringExpenses,
    List<dynamic> goals,
  ) async {
    final recommendedCategories = <Map<String, dynamic>>[];
    final availableIncome = income > monthlyRecurringExpenses
        ? income - monthlyRecurringExpenses
        : 0.0;
    final recurringPercentage =
        income > 0 ? (monthlyRecurringExpenses / income) * 100 : 0;
    
    // If income is 0 or very small, show minimal template
    if (income <= 0) {
      return {
        'total_income': 0.0,
        'monthly_recurring_expenses': monthlyRecurringExpenses,
        'available_income': 0.0,
        'categories': monthlyRecurringExpenses > 0
            ? [
                {
                  'name': 'Tagihan & Langganan Rutin',
                  'percentage': 100.0,
                  'amount': monthlyRecurringExpenses,
                  'icon': Iconsax.receipt_2,
                  'color': const Color(0xFFFF5252),
                  'description': '⚡ Dari tagihan & langganan Anda yang aktif',
                  'flexibility': 'fixed',
                  'is_recurring': true,
                  'subcategories': <dynamic>[],
                },
              ]
            : [],
        'allocation_method': 'template',
        'months_analyzed': 0,
        'historical_average_expense': 0.0,
        'recommended_savings_rate': 0.0,
        'is_new_user': true,
        'has_only_income': false,
        'message':
            'Masukkan pendapatan bulanan Anda untuk mendapatkan rekomendasi budget yang lengkap.',
      };
    }

    // 1. Recurring Bills & Subscriptions (fixed)
    if (monthlyRecurringExpenses > 0) {
      recommendedCategories.add({
        'name': 'Tagihan & Langganan Rutin',
        'percentage': recurringPercentage,
        'amount': monthlyRecurringExpenses,
        'icon': Iconsax.receipt_2,
        'color': const Color(0xFFFF5252),
        'description': '⚡ Dari tagihan & langganan Anda yang aktif',
        'flexibility': 'fixed',
        'is_recurring': true,
      });
    }

    // 2. Essential Needs (50% of available income)
    final essentialCategories = [
      {'name': 'Makanan', 'percentage': 20.0, 'icon': Iconsax.cake},
      {'name': 'Transportasi', 'percentage': 15.0, 'icon': Iconsax.car},
      {'name': 'Kebutuhan Pokok', 'percentage': 10.0, 'icon': Iconsax.wallet},
      {'name': 'Tagihan', 'percentage': 5.0, 'icon': Iconsax.receipt},
    ];

    for (var cat in essentialCategories) {
      final catAmount = availableIncome * ((cat['percentage'] as double) / 100);
      recommendedCategories.add({
        'name': cat['name'],
        'percentage': cat['percentage'],
        'amount': catAmount,
        'icon': cat['icon'],
        'color': _getCategoryColor(cat['name'] as String),
        'description': '💡 Rekomendasi awal untuk user baru (dapat disesuaikan)',
        'flexibility': 'moderate',
        'is_template': true,
        'subcategories': <dynamic>[],
      });
    }

    // 3. Discretionary Spending (30% of available income)
    final discretionaryCategories = [
      {'name': 'Hiburan', 'percentage': 15.0, 'icon': Iconsax.music},
      {'name': 'Shopping', 'percentage': 10.0, 'icon': Iconsax.shopping_bag},
      {'name': 'Hobi', 'percentage': 5.0, 'icon': Iconsax.game},
    ];

    for (var cat in discretionaryCategories) {
      final catAmount = availableIncome * ((cat['percentage'] as double) / 100);
      recommendedCategories.add({
        'name': cat['name'],
        'percentage': cat['percentage'],
        'amount': catAmount,
        'icon': cat['icon'],
        'color': _getCategoryColor(cat['name'] as String),
        'description': '💡 Rekomendasi awal - sesuaikan sesuai kebutuhan Anda',
        'flexibility': 'high',
        'is_template': true,
        'subcategories': <dynamic>[],
      });
    }

    // 4. Savings & Investments (20% of available income, or goal-adjusted)
    final baseSavingsPercentage = 20.0;
    final goalAdjustments = _calculateGoalAdjustments(goals, income, 0.0);
    final goalSavingsAdjustment = goalAdjustments['savings'] as double? ?? 0.0;

    final savingsAmount =
        (availableIncome * (baseSavingsPercentage / 100)) + goalSavingsAdjustment;
    final savingsPercentage = income > 0 ? (savingsAmount / income) * 100 : 0;

    recommendedCategories.add({
      'name': 'Tabungan & Investasi',
      'percentage': savingsPercentage,
      'amount': savingsAmount,
      'icon': Iconsax.chart,
      'color': const Color(0xFF2196F3),
      'description': goalSavingsAdjustment > 0
          ? 'Target: ${baseSavingsPercentage.toStringAsFixed(0)}% + penyesuaian untuk goals Anda'
          : 'Target: ${baseSavingsPercentage.toStringAsFixed(0)}% dari pendapatan (rekomendasi standar)',
      'flexibility': 'low',
      'target_rate': baseSavingsPercentage,
      'goal_adjusted': goalSavingsAdjustment > 0,
      'is_template': true,
      'subcategories': <dynamic>[],
    });

    // 5. Emergency Fund (if no emergency goal)
    final hasEmergencyFundGoal = goals.any(
      (g) =>
          (g['type']?.toString().toLowerCase() ?? '').contains('emergency') ||
          (g['name']?.toString().toLowerCase() ?? '').contains('darurat'),
    );

    if (!hasEmergencyFundGoal) {
      final emergencyAmount = income * 0.10;
      recommendedCategories.add({
        'name': 'Dana Darurat',
        'percentage': 10.0,
        'amount': emergencyAmount,
        'icon': Iconsax.shield_tick,
        'color': const Color(0xFFFF9800),
        'description': 'Target: 6 bulan pengeluaran (rekomendasi standar)',
        'flexibility': 'low',
        'is_template': true,
        'subcategories': <dynamic>[],
      });
    }

    // Determine message based on context
    String message;
    if (income > 0 && monthlyRecurringExpenses == 0) {
      message =
          'Rekomendasi ini menggunakan template standar berdasarkan pendapatan Anda. '
          'Mulai catat pengeluaran untuk mendapatkan rekomendasi yang lebih personal.';
    } else if (income > 0) {
      message =
          'Rekomendasi ini menggunakan template standar. '
          'Setelah Anda mulai mencatat transaksi pengeluaran, rekomendasi akan disesuaikan dengan pola pengeluaran Anda.';
    } else {
      message =
          'Rekomendasi ini menggunakan template standar. '
          'Masukkan pendapatan dan mulai catat transaksi untuk mendapatkan rekomendasi yang lebih akurat.';
    }

    return {
      'total_income': income,
      'monthly_recurring_expenses': monthlyRecurringExpenses,
      'available_income': availableIncome,
      'categories': recommendedCategories,
      'allocation_method': 'template', // Indicates this is template-based
      'months_analyzed': 0,
      'historical_average_expense': 0.0,
      'recommended_savings_rate': baseSavingsPercentage,
      'is_new_user': true,
      'has_only_income': income > 0 && monthlyRecurringExpenses == 0,
      'message': message,
    };
  }
}
