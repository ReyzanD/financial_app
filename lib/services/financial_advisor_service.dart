import 'package:financial_app/services/data/transaction_data_service.dart';
import 'package:financial_app/services/data/goal_data_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/core/di/service_locator.dart';

/// 50/30/20 budget analysis result for a single period.
class FiftyThirtyTwentyAnalysis {
  final double monthlyIncome;
  final double monthlyExpense;
  final double savings;

  // Actual spending
  final double needsActual;
  final double wantsActual;

  // 50/30/20 targets
  final double needsTarget;
  final double wantsTarget;
  final double savingsTarget;

  // Percentage of income
  final double needsPercent;
  final double wantsPercent;
  final double savingsPercent;

  // Category breakdowns
  final List<CategoryBreakdown> needsCategories;
  final List<CategoryBreakdown> wantsCategories;

  // Gap analysis
  final double needsGap; // positive = over budget
  final double wantsGap;
  final double savingsGap; // positive = under-saving

  // Goal run-rate
  final List<GoalRunRate> goalRunRates;

  const FiftyThirtyTwentyAnalysis({
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.savings,
    required this.needsActual,
    required this.wantsActual,
    required this.needsTarget,
    required this.wantsTarget,
    required this.savingsTarget,
    required this.needsPercent,
    required this.wantsPercent,
    required this.savingsPercent,
    required this.needsCategories,
    required this.wantsCategories,
    required this.needsGap,
    required this.wantsGap,
    required this.savingsGap,
    required this.goalRunRates,
  });
}

class CategoryBreakdown {
  final String name;
  final double amount;
  final double percentOfIncome;

  const CategoryBreakdown({
    required this.name,
    required this.amount,
    required this.percentOfIncome,
  });
}

class GoalRunRate {
  final String name;
  final double targetAmount;
  final double currentAmount;
  final double monthlyContribution;
  final double progressPercent;
  final int monthsToGoal; // -1 if not on track

  const GoalRunRate({
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.monthlyContribution,
    required this.progressPercent,
    required this.monthsToGoal,
  });
}

/// An actionable suggestion generated from a 50/30/20 analysis.
///
/// Each suggestion identifies one overspent category and estimates how much
/// the user could save if they reduced spending to the target level, plus
/// links to Phase 2 alternative recommendations when available.
class SavingsSuggestion {
  final String categoryName;
  final String type; // 'needs' or 'wants'
  final double currentAmount;
  final double targetAmount;
  final double gap; // positive = over budget
  final double targetPercent; // 50 for needs, 30 for wants
  final double potentialMonthlySavings; // how much they could save per month
  final bool hasAlternatives; // whether Phase 2 has alternative data

  const SavingsSuggestion({
    required this.categoryName,
    required this.type,
    required this.currentAmount,
    required this.targetAmount,
    required this.gap,
    required this.targetPercent,
    required this.potentialMonthlySavings,
    this.hasAlternatives = false,
  });
}

/// Financial Advisor — applies the 50/30/20 budgeting model to the user's
/// actual transactions and shows the real math behind their spending.
class FinancialAdvisorService {
  final TransactionDataService _transactionData;

  FinancialAdvisorService({TransactionDataService? transactionData})
    : _transactionData = transactionData ?? TransactionDataService();

  /// Categories classified as essential needs (50%).
  static const Set<String> needCategoryNames = {
    'Makanan & Minuman',
    'Makanan',
    'Transportasi',
    'Kebutuhan Pokok',
    'Tagihan & Utilitas',
    'Tagihan',
    'Kesehatan',
    'Pendidikan',
    'Asuransi',
    'Sewa',
    'Listrik',
    'Air',
    'Pulsa',
    'Internet',
  };

  /// Categories classified as discretionary wants (30%).
  static const Set<String> wantCategoryNames = {
    'Hiburan',
    'Belanja',
    'Shopping',
    'Hobi',
    'Lifestyle',
    'Liburan',
    'Travel',
    'Makan di Luar',
    'Kafe',
    'Nongkrong',
    'Game',
    'Streaming',
    'Fashion',
  };

  /// Run the full 50/30/20 analysis for the current month.
  Future<FiftyThirtyTwentyAnalysis> analyzeCurrentMonth() async {
    final now = DateTime.now();
    return analyzeForPeriod(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
  }

  /// Run 50/30/20 analysis for a specific date range.
  Future<FiftyThirtyTwentyAnalysis> analyzeForPeriod({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final startStr = start.toIso8601String().split('T')[0];
      final endStr = end.toIso8601String().split('T')[0];

      final txData = await _transactionData.getTransactions(
        startDate: startStr,
        endDate: endStr,
        limit: 5000,
      );
      final transactions = List<Map<String, dynamic>>.from(
        txData['transactions'] ?? [],
      );

      final goalRunRates = await _computeGoalRunRates();

      return computeAnalysis(transactions, goals: goalRunRates);
    } catch (e) {
      LoggerService.error('Error in 50/30/20 analysis', error: e);
      rethrow;
    }
  }

  /// Run analysis for each of the last [count] months (including current).
  /// Returns a list ordered from oldest to newest.
  Future<List<FiftyThirtyTwentyAnalysis>> analyzeMultiMonth(int count) async {
    final now = DateTime.now();
    final results = <FiftyThirtyTwentyAnalysis>[];
    for (int i = count - 1; i >= 0; i--) {
      final start = DateTime(now.year, now.month - i, 1);
      final end = DateTime(now.year, now.month - i + 1, 0);
      if (start.isAfter(now)) break;
      try {
        results.add(await analyzeForPeriod(start: start, end: end));
      } catch (e) {
        LoggerService.error('Error analyzing month -$i', error: e);
        // Add empty analysis so indices stay aligned
        results.add(computeAnalysis([]));
      }
    }
    return results;
  }

  /// Pure computation — no I/O. Extracted for testability.
  static FiftyThirtyTwentyAnalysis computeAnalysis(
    List<Map<String, dynamic>> transactions, {
    List<GoalRunRate> goals = const [],
  }) {
    double monthlyIncome = 0;
    double monthlyExpense = 0;
    final needsMap = <String, double>{};
    final wantsMap = <String, double>{};

    for (final tx in transactions) {
      final amount =
          (tx['amount_232143'] as num?)?.toDouble() ??
          (tx['amount'] as num?)?.toDouble() ??
          0.0;
      final type =
          tx['type_232143']?.toString() ?? tx['type']?.toString() ?? 'expense';
      final category =
          tx['category_name']?.toString() ??
          tx['category']?.toString() ??
          'Lainnya';

      if (type == 'income') {
        monthlyIncome += amount;
      } else if (type == 'expense') {
        monthlyExpense += amount;
        if (needCategoryNames.contains(category)) {
          needsMap[category] = (needsMap[category] ?? 0) + amount;
        } else if (wantCategoryNames.contains(category)) {
          wantsMap[category] = (wantsMap[category] ?? 0) + amount;
        } else {
          // Uncategorized — default to needs (conservative)
          needsMap[category] = (needsMap[category] ?? 0) + amount;
        }
      }
    }

    final savings = monthlyIncome - monthlyExpense;
    final needsActual = needsMap.values.fold(0.0, (a, b) => a + b);
    final wantsActual = wantsMap.values.fold(0.0, (a, b) => a + b);

    // 50/30/20 targets
    final needsTarget = monthlyIncome * 0.50;
    final wantsTarget = monthlyIncome * 0.30;
    final savingsTarget = monthlyIncome * 0.20;

    // Percentages
    final needsPercent =
        monthlyIncome > 0 ? (needsActual / monthlyIncome) * 100 : 0.0;
    final wantsPercent =
        monthlyIncome > 0 ? (wantsActual / monthlyIncome) * 100 : 0.0;
    final savingsPercent =
        monthlyIncome > 0 ? (savings / monthlyIncome) * 100 : 0.0;

    // Gap analysis (positive = over budget)
    final needsGap = needsActual - needsTarget;
    final wantsGap = wantsActual - wantsTarget;
    final savingsGap = savingsTarget - savings;

    // Category breakdowns
    final needBreakdowns =
        needsMap.entries
            .map(
              (e) => CategoryBreakdown(
                name: e.key,
                amount: e.value,
                percentOfIncome:
                    monthlyIncome > 0 ? (e.value / monthlyIncome) * 100 : 0.0,
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    final wantBreakdowns =
        wantsMap.entries
            .map(
              (e) => CategoryBreakdown(
                name: e.key,
                amount: e.value,
                percentOfIncome:
                    monthlyIncome > 0 ? (e.value / monthlyIncome) * 100 : 0.0,
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    return FiftyThirtyTwentyAnalysis(
      monthlyIncome: monthlyIncome,
      monthlyExpense: monthlyExpense,
      savings: savings,
      needsActual: needsActual,
      wantsActual: wantsActual,
      needsTarget: needsTarget,
      wantsTarget: wantsTarget,
      savingsTarget: savingsTarget,
      needsPercent: needsPercent,
      wantsPercent: wantsPercent,
      savingsPercent: savingsPercent,
      needsCategories: needBreakdowns,
      wantsCategories: wantBreakdowns,
      needsGap: needsGap,
      wantsGap: wantsGap,
      savingsGap: savingsGap,
      goalRunRates: goals,
    );
  }

  Future<List<GoalRunRate>> _computeGoalRunRates() async {
    try {
      final goals = await getIt<GoalDataService>().getGoals();
      final result = <GoalRunRate>[];

      for (final goal in goals) {
        final monthlyContribution = goal.monthlyTarget ?? 0.0;
        final progressPercent =
            goal.targetAmount > 0
                ? (goal.currentAmount / goal.targetAmount) * 100
                : 0.0;

        int monthsToGoal = -1;
        if (monthlyContribution > 0) {
          final remaining = goal.targetAmount - goal.currentAmount;
          monthsToGoal = (remaining / monthlyContribution).ceil();
        }

        result.add(
          GoalRunRate(
            name: goal.name,
            targetAmount: goal.targetAmount,
            currentAmount: goal.currentAmount,
            monthlyContribution: monthlyContribution,
            progressPercent: progressPercent,
            monthsToGoal: monthsToGoal,
          ),
        );
      }

      return result;
    } catch (e) {
      LoggerService.error('Error computing goal run rates', error: e);
      return [];
    }
  }

  /// Get a human-readable assessment of the user's financial health.
  String getAssessment(FiftyThirtyTwentyAnalysis analysis) {
    final parts = <String>[];
    if (analysis.monthlyIncome <= 0) {
      return 'Belum ada data pemasukan bulan ini. Tambahkan transaksi untuk melihat analisis.';
    }

    if (analysis.needsPercent > 50) {
      parts.add(
        'Kebutuhan pokok ${analysis.needsPercent.toStringAsFixed(0)}% dari '
        'pendapatan (target 50%). ${_formatRupiah(analysis.needsGap)} melebihi batas.',
      );
    } else {
      parts.add(
        'Kebutuhan pokok ${analysis.needsPercent.toStringAsFixed(0)}% — '
        'dalam batas 50% ✅',
      );
    }

    if (analysis.wantsPercent > 30) {
      parts.add(
        'Pengeluaran discretionary ${analysis.wantsPercent.toStringAsFixed(0)}% '
        'dari pendapatan (target 30%). ${_formatRupiah(analysis.wantsGap)} melebihi batas.',
      );
    } else {
      parts.add(
        'Keinginan ${analysis.wantsPercent.toStringAsFixed(0)}% — '
        'dalam batas 30% ✅',
      );
    }

    if (analysis.savingsPercent < 20) {
      parts.add(
        'Tabungan ${analysis.savingsPercent.toStringAsFixed(0)}% dari target 20%. '
        '${_formatRupiah(analysis.savingsGap)} kurang dari target.',
      );
    } else {
      parts.add(
        'Tabungan ${analysis.savingsPercent.toStringAsFixed(0)}% — '
        'mencapai target 20% ✅',
      );
    }

    if (analysis.goalRunRates.isNotEmpty) {
      final onTrack = analysis.goalRunRates.where((g) => g.monthsToGoal >= 0);
      if (onTrack.isNotEmpty) {
        final soonest = onTrack.reduce(
          (a, b) => a.monthsToGoal < b.monthsToGoal ? a : b,
        );
        parts.add(
          'Goal terdekat: "${soonest.name}" tercapai dalam '
          '${soonest.monthsToGoal} bulan.',
        );
      }
    }

    return parts.join('\n\n');
  }

  /// Generate actionable savings suggestions from the analysis.
  ///
  /// Identifies overspent categories and estimates how much the user could
  /// save each month by bringing spending back to target levels.
  static List<SavingsSuggestion> generateSuggestions(
    FiftyThirtyTwentyAnalysis analysis,
  ) {
    if (analysis.monthlyIncome <= 0) return [];

    final suggestions = <SavingsSuggestion>[];

    // Check needs categories that are significantly over budget
    for (final cat in analysis.needsCategories) {
      if (cat.amount > analysis.monthlyIncome * 0.15) {
        // Single category exceeds 15% of income — actionable
        final targetForCategory = analysis.monthlyIncome * 0.15;
        final overspend = cat.amount - targetForCategory;
        suggestions.add(
          SavingsSuggestion(
            categoryName: cat.name,
            type: 'needs',
            currentAmount: cat.amount,
            targetAmount: targetForCategory,
            gap: overspend,
            targetPercent: 50,
            potentialMonthlySavings: overspend > 0 ? overspend : 0,
          ),
        );
      }
    }

    // If overall needs > 50%, add an aggregate suggestion for the top category
    if (analysis.needsGap > 0 && analysis.needsCategories.isNotEmpty) {
      final topNeed = analysis.needsCategories.first;
      final alreadySuggested = suggestions.any(
        (s) => s.categoryName == topNeed.name,
      );
      if (!alreadySuggested) {
        // Suggest reducing the top need category by a portion of the gap
        final reduction = (analysis.needsGap * 0.5).clamp(
          0.0,
          topNeed.amount * 0.3,
        );
        if (reduction > 10000) {
          suggestions.add(
            SavingsSuggestion(
              categoryName: topNeed.name,
              type: 'needs',
              currentAmount: topNeed.amount,
              targetAmount: topNeed.amount - reduction,
              gap: analysis.needsGap,
              targetPercent: 50,
              potentialMonthlySavings: reduction,
            ),
          );
        }
      }
    }

    // Check wants categories
    for (final cat in analysis.wantsCategories) {
      if (cat.amount > analysis.monthlyIncome * 0.10) {
        // Single wants category exceeds 10% of income
        final targetForCategory = analysis.monthlyIncome * 0.10;
        final overspend = cat.amount - targetForCategory;
        suggestions.add(
          SavingsSuggestion(
            categoryName: cat.name,
            type: 'wants',
            currentAmount: cat.amount,
            targetAmount: targetForCategory,
            gap: overspend > 0 ? overspend : 0,
            targetPercent: 30,
            potentialMonthlySavings: overspend > 0 ? overspend : 0,
          ),
        );
      }
    }

    // If overall wants > 30%, add aggregate
    if (analysis.wantsGap > 0 && analysis.wantsCategories.isNotEmpty) {
      final topWant = analysis.wantsCategories.first;
      final alreadySuggested = suggestions.any(
        (s) => s.categoryName == topWant.name,
      );
      if (!alreadySuggested) {
        final reduction = (analysis.wantsGap * 0.5).clamp(
          0.0,
          topWant.amount * 0.3,
        );
        if (reduction > 10000) {
          suggestions.add(
            SavingsSuggestion(
              categoryName: topWant.name,
              type: 'wants',
              currentAmount: topWant.amount,
              targetAmount: topWant.amount - reduction,
              gap: analysis.wantsGap,
              targetPercent: 30,
              potentialMonthlySavings: reduction,
            ),
          );
        }
      }
    }

    // Sort by potential savings descending, take top 5
    suggestions.sort(
      (a, b) => b.potentialMonthlySavings.compareTo(a.potentialMonthlySavings),
    );
    return suggestions.take(5).toList();
  }

  String _formatRupiah(double amount) {
    final abs = amount.abs();
    final prefix = amount > 0 ? 'Rp ' : '-Rp ';
    if (abs >= 1000000) {
      return '$prefix${(abs / 1000000).toStringAsFixed(1)}jt';
    }
    return '$prefix${abs.toStringAsFixed(0)}';
  }
}
