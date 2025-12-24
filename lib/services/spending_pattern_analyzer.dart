import 'package:financial_app/services/logger_service.dart';

/// Advanced spending pattern analyzer with multi-period analysis,
/// trend detection, category correlation, day-of-week patterns, and merchant frequency
class SpendingPatternAnalyzer {
  /// Analyze spending patterns across multiple periods (3+ months)
  Map<String, dynamic> analyzeMultiPeriod({
    required List<dynamic> transactions,
    int monthsToAnalyze = 3,
  }) {
    try {
      final now = DateTime.now();
      final periodData = <String, Map<String, dynamic>>{};

      // Group transactions by month
      for (int i = 0; i < monthsToAnalyze; i++) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final monthKey =
            '${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}';

        final monthTransactions =
            transactions.where((t) {
              try {
                final dateStr =
                    t['transaction_date']?.toString() ??
                    t['date']?.toString() ??
                    '';
                if (dateStr.isEmpty) return false;
                final date = DateTime.parse(dateStr);
                return date.year == monthDate.year &&
                    date.month == monthDate.month;
              } catch (e) {
                return false;
              }
            }).toList();

        double monthIncome = 0;
        double monthExpense = 0;
        final categorySpending = <String, double>{};
        final dayOfWeekSpending = <int, double>{}; // 1 = Monday, 7 = Sunday
        final merchantFrequency = <String, int>{};

        for (var t in monthTransactions) {
          final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
          final type = t['type']?.toString().toLowerCase() ?? 'expense';
          final category = t['category_name']?.toString() ?? 'Lainnya';
          final description = (t['description'] ?? '').toString().toLowerCase();

          if (type == 'income') {
            monthIncome += amount;
          } else if (type == 'expense') {
            monthExpense += amount;
            categorySpending[category] =
                (categorySpending[category] ?? 0) + amount;

            // Day of week analysis
            try {
              final dateStr =
                  t['transaction_date']?.toString() ??
                  t['date']?.toString() ??
                  '';
              if (dateStr.isNotEmpty) {
                final date = DateTime.parse(dateStr);
                final weekday = date.weekday; // 1 = Monday, 7 = Sunday
                dayOfWeekSpending[weekday] =
                    (dayOfWeekSpending[weekday] ?? 0) + amount;
              }
            } catch (e) {
              // Skip if date parsing fails
            }

            // Merchant frequency (extract merchant from description)
            if (description.isNotEmpty && amount > 10000) {
              // Extract potential merchant name (first few words)
              final words = description.split(' ').take(2).join(' ');
              if (words.length > 3) {
                merchantFrequency[words] = (merchantFrequency[words] ?? 0) + 1;
              }
            }
          }
        }

        periodData[monthKey] = {
          'income': monthIncome,
          'expense': monthExpense,
          'savings_rate':
              monthIncome > 0
                  ? ((monthIncome - monthExpense) / monthIncome) * 100
                  : 0,
          'category_spending': categorySpending,
          'day_of_week_spending': dayOfWeekSpending,
          'merchant_frequency': merchantFrequency,
          'transaction_count': monthTransactions.length,
        };
      }

      // Calculate trends
      final trends = _calculateTrends(periodData);

      // Calculate category correlations
      final categoryCorrelations = _calculateCategoryCorrelations(periodData);

      // Identify day-of-week patterns
      final dayOfWeekPatterns = _identifyDayOfWeekPatterns(periodData);

      // Identify frequent merchants
      final frequentMerchants = _identifyFrequentMerchants(periodData);

      return {
        'period_data': periodData,
        'trends': trends,
        'category_correlations': categoryCorrelations,
        'day_of_week_patterns': dayOfWeekPatterns,
        'frequent_merchants': frequentMerchants,
        'months_analyzed': monthsToAnalyze,
      };
    } catch (e) {
      LoggerService.error('Error analyzing multi-period patterns', error: e);
      return {};
    }
  }

  /// Calculate spending trends across periods
  Map<String, dynamic> _calculateTrends(Map<String, dynamic> periodData) {
    final trends = <String, dynamic>{};
    final sortedMonths = periodData.keys.toList()..sort();

    if (sortedMonths.length < 2) {
      return {
        'expense_trend': 'insufficient_data',
        'income_trend': 'insufficient_data',
      };
    }

    // Calculate expense trend
    final expenses =
        sortedMonths
            .map((m) => ((periodData[m] as Map)['expense'] as num?)?.toDouble() ?? 0.0)
            .toList();
    final expenseChange =
        expenses.length > 1 && expenses.isNotEmpty && expenses.first > 0
            ? ((expenses.last - expenses.first) / expenses.first) * 100
            : 0.0;

    // Calculate income trend
    final incomes =
        sortedMonths
            .map((m) => ((periodData[m] as Map)['income'] as num?)?.toDouble() ?? 0.0)
            .toList();
    final incomeChange =
        incomes.length > 1 && incomes.isNotEmpty && incomes.first > 0
            ? ((incomes.last - incomes.first) / incomes.first) * 100
            : 0.0;

    // Calculate savings rate trend
    final savingsRates =
        sortedMonths
            .map((m) => ((periodData[m] as Map)['savings_rate'] as num?)?.toDouble() ?? 0.0)
            .toList();
    final savingsRateChange =
        savingsRates.length > 1 && savingsRates.isNotEmpty
            ? savingsRates.last - savingsRates.first
            : 0.0;

    trends['expense_trend'] =
        expenseChange > 5
            ? 'increasing'
            : expenseChange < -5
            ? 'decreasing'
            : 'stable';
    trends['expense_change_percent'] = expenseChange;

    trends['income_trend'] =
        incomeChange > 5
            ? 'increasing'
            : incomeChange < -5
            ? 'decreasing'
            : 'stable';
    trends['income_change_percent'] = incomeChange;

    trends['savings_rate_trend'] =
        savingsRateChange > 2
            ? 'improving'
            : savingsRateChange < -2
            ? 'declining'
            : 'stable';
    trends['savings_rate_change'] = savingsRateChange;

    // Category trends
    final categoryTrends = <String, String>{};
    final allCategories = <String>{};
    for (var monthData in periodData.values) {
      final catSpendingRaw = (monthData as Map)['category_spending'];
      if (catSpendingRaw is Map) {
        final catSpending = Map<String, double>.from(
          catSpendingRaw.map(
            (key, value) => MapEntry(
              key.toString(),
              ((value as num?)?.toDouble() ?? 0.0),
            ),
          ),
        );
        allCategories.addAll(catSpending.keys);
      }
    }

    for (var category in allCategories) {
      final categoryAmounts = <double>[];
      for (var month in sortedMonths) {
        final catSpendingRaw = (periodData[month] as Map)['category_spending'];
        if (catSpendingRaw is Map) {
          final catSpending = Map<String, double>.from(
            catSpendingRaw.map(
              (key, value) => MapEntry(
                key.toString(),
                ((value as num?)?.toDouble() ?? 0.0),
              ),
            ),
          );
          categoryAmounts.add(catSpending[category] ?? 0.0);
        } else {
          categoryAmounts.add(0.0);
        }
      }

      if (categoryAmounts.length >= 2 && categoryAmounts.isNotEmpty) {
        final change =
            ((categoryAmounts.last - categoryAmounts.first) /
                (categoryAmounts.first > 0 ? categoryAmounts.first : 1)) *
            100;
        categoryTrends[category] =
            change > 10
                ? 'increasing'
                : change < -10
                ? 'decreasing'
                : 'stable';
      }
    }
    trends['category_trends'] = categoryTrends;

    return trends;
  }

  /// Calculate correlations between categories
  Map<String, double> _calculateCategoryCorrelations(
    Map<String, dynamic> periodData,
  ) {
    final correlations = <String, double>{};
    final sortedMonths = periodData.keys.toList()..sort();

    if (sortedMonths.length < 2) return correlations;

    // Get all categories
    final allCategories = <String>{};
    for (var monthData in periodData.values) {
      final catSpendingRaw = (monthData as Map)['category_spending'];
      if (catSpendingRaw is Map) {
        final catSpending = Map<String, double>.from(
          catSpendingRaw.map(
            (key, value) => MapEntry(
              key.toString(),
              ((value as num?)?.toDouble() ?? 0.0),
            ),
          ),
        );
        allCategories.addAll(catSpending.keys);
      }
    }

    final categoryList = allCategories.toList();

    // Calculate correlation between each pair of categories
    for (int i = 0; i < categoryList.length; i++) {
      for (int j = i + 1; j < categoryList.length; j++) {
        final cat1 = categoryList[i];
        final cat2 = categoryList[j];

        final cat1Amounts = <double>[];
        final cat2Amounts = <double>[];

        for (var month in sortedMonths) {
          final catSpendingRaw = (periodData[month] as Map)['category_spending'];
          if (catSpendingRaw is Map) {
            final catSpending = Map<String, double>.from(
              catSpendingRaw.map(
                (key, value) => MapEntry(
                  key.toString(),
                  ((value as num?)?.toDouble() ?? 0.0),
                ),
              ),
            );
            cat1Amounts.add(catSpending[cat1] ?? 0.0);
            cat2Amounts.add(catSpending[cat2] ?? 0.0);
          } else {
            cat1Amounts.add(0.0);
            cat2Amounts.add(0.0);
          }
        }

        // Calculate Pearson correlation
        final correlation = _calculatePearsonCorrelation(
          cat1Amounts,
          cat2Amounts,
        );
        if (correlation.abs() > 0.5) {
          // Only store significant correlations
          correlations['$cat1 vs $cat2'] = correlation;
        }
      }
    }

    return correlations;
  }

  /// Calculate Pearson correlation coefficient
  double _calculatePearsonCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.isEmpty) return 0.0;

    final n = x.length;
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = x
        .asMap()
        .entries
        .map((e) => e.value * y[e.key])
        .reduce((a, b) => a + b);
    final sumX2 = x.map((v) => v * v).reduce((a, b) => a + b);
    final sumY2 = y.map((v) => v * v).reduce((a, b) => a + b);

    final numerator = (n * sumXY) - (sumX * sumY);
    final denominator = ((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));

    if (denominator == 0) return 0.0;

    return numerator / denominator;
  }

  /// Identify day-of-week spending patterns
  Map<String, dynamic> _identifyDayOfWeekPatterns(
    Map<String, dynamic> periodData,
  ) {
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final dayTotals = <int, double>{};

    // Aggregate spending by day of week across all months
    for (var monthData in periodData.values) {
      final daySpendingRaw = (monthData as Map)['day_of_week_spending'];
      if (daySpendingRaw is Map) {
        final daySpending = Map<int, double>.from(
          daySpendingRaw.map(
            (key, value) => MapEntry(
              ((key as num?)?.toInt() ?? 0),
              ((value as num?)?.toDouble() ?? 0.0),
            ),
          ),
        );
        daySpending.forEach((day, amount) {
          dayTotals[day] = (dayTotals[day] ?? 0) + amount;
        });
      }
    }

    // Find peak spending day
    int? peakDay;
    double maxSpending = 0;
    dayTotals.forEach((day, amount) {
      if (amount > maxSpending) {
        maxSpending = amount;
        peakDay = day;
      }
    });

    // Calculate average per day
    final avgPerDay = dayTotals.values.isNotEmpty
        ? dayTotals.values.reduce((a, b) => a + b) / dayTotals.length
        : 0.0;

    return {
      'day_totals': dayTotals,
      'peak_day': peakDay != null ? dayNames[peakDay! - 1] : null,
      'peak_day_amount': maxSpending,
      'average_per_day': avgPerDay,
      'pattern':
          peakDay != null && maxSpending > avgPerDay * 1.2
              ? 'Peak spending on ${dayNames[peakDay! - 1]}'
              : 'Even distribution',
    };
  }

  /// Identify frequent merchants
  List<Map<String, dynamic>> _identifyFrequentMerchants(
    Map<String, dynamic> periodData,
  ) {
    final merchantCounts = <String, int>{};

    // Aggregate merchant data across all months
    for (var monthData in periodData.values) {
      final merchantFreqRaw = (monthData as Map)['merchant_frequency'];
      if (merchantFreqRaw is Map) {
        final merchantFreq = Map<String, int>.from(
          merchantFreqRaw.map(
            (key, value) => MapEntry(
              key.toString(),
              ((value as num?)?.toInt() ?? 0),
            ),
          ),
        );
        merchantFreq.forEach((merchant, count) {
          merchantCounts[merchant] = (merchantCounts[merchant] ?? 0) + count;
        });
      }
    }

    // Sort by frequency
    final sortedMerchants =
        merchantCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return sortedMerchants.take(10).map((entry) {
      return {
        'merchant': entry.key,
        'frequency': entry.value,
        'suggestion':
            entry.value >= 3
                ? 'Consider setting up a recurring transaction or subscription budget'
                : null,
      };
    }).toList();
  }
}
