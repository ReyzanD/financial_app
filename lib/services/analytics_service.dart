import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';
import 'package:financial_app/core/di/service_locator.dart';

class AnalyticsService {
  final TransactionDataService _transactionData = getIt<TransactionDataService>();

  /// Get analytics data for a specific period
  Future<Map<String, dynamic>> getAnalytics({
    required String period, // 'week', 'month', 'year'
  }) async {
    try {
      // Get transactions for the period
      final txData = await _transactionData.getTransactions(limit: 1000);
      final transactions = List<Map<String, dynamic>>.from(txData['transactions'] ?? []);

      // Filter by period
      final now = DateTime.now();
      final filteredTransactions = _filterByPeriod(transactions, period, now);

      // Calculate analytics
      return _calculateAnalytics(filteredTransactions, period, now);
    } catch (e) {
      LoggerService.error('Error getting analytics', error: e);
      rethrow;
    }
  }

  List<Map<String, dynamic>> _filterByPeriod(List<Map<String, dynamic>> transactions, String period, DateTime now) {
    return transactions.where((t) {
      try {
        final dateStr =
            t['transaction_date_232143']?.toString() ??
            t['transaction_date']?.toString() ??
            t['date']?.toString() ??
            '';
        final date = DateTime.parse(dateStr);

        switch (period) {
          case 'week':
            final weekAgo = now.subtract(const Duration(days: 7));
            return date.isAfter(weekAgo);
          case 'month':
            return date.month == now.month && date.year == now.year;
          case 'year':
            return date.year == now.year;
          default:
            return true;
        }
      } catch (e) {
        return false;
      }
    }).toList();
  }

  Map<String, dynamic> _calculateAnalytics(List<Map<String, dynamic>> transactions, String period, DateTime now) {
    double totalIncome = 0;
    double totalExpense = 0;
    Map<String, double> categoryExpenses = {};
    Map<String, double> categoryIncome = {};
    List<Map<String, dynamic>> dailyData = [];

    // Process transactions
    for (var transaction in transactions) {
      final amount =
          (transaction['amount_232143'] as num?)?.toDouble() ?? (transaction['amount'] as num?)?.toDouble() ?? 0.0;
      final type =
          transaction['type_232143']?.toString().toLowerCase() ??
          transaction['type']?.toString().toLowerCase() ??
          'expense';
      final category = transaction['category_name']?.toString() ?? 'Lainnya';

      if (type == 'income') {
        totalIncome += amount;
        categoryIncome[category] = (categoryIncome[category] ?? 0) + amount;
      } else if (type == 'expense') {
        totalExpense += amount;
        categoryExpenses[category] = (categoryExpenses[category] ?? 0) + amount;
      }
    }

    // Calculate daily/monthly trend
    dailyData = _calculateTrendData(transactions, period, now);

    // Get top categories
    final topExpenseCategories = _getTopCategories(categoryExpenses, 5);
    final topIncomeCategories = _getTopCategories(categoryIncome, 5);

    // Calculate savings
    final savings = totalIncome - totalExpense;
    final savingsRate = totalIncome > 0 ? (savings / totalIncome) * 100 : 0;

    // Get previous period data for comparison
    final previousPeriodData = _getPreviousPeriodComparison(transactions, period, now);

    return {
      'period': period,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'savings': savings,
      'savingsRate': savingsRate,
      'transactionCount': transactions.length,
      'categoryExpenses': categoryExpenses,
      'categoryIncome': categoryIncome,
      'topExpenseCategories': topExpenseCategories,
      'topIncomeCategories': topIncomeCategories,
      'dailyData': dailyData,
      'averageDailyExpense': dailyData.isNotEmpty ? totalExpense / dailyData.length : 0,
      'previousPeriod': previousPeriodData,
    };
  }

  List<Map<String, dynamic>> _calculateTrendData(List<Map<String, dynamic>> transactions, String period, DateTime now) {
    Map<String, Map<String, double>> dataByDate = {};

    for (var transaction in transactions) {
      try {
        final dateStr =
            transaction['transaction_date_232143']?.toString() ??
            transaction['transaction_date']?.toString() ??
            transaction['date']?.toString() ??
            '';
        final date = DateTime.parse(dateStr);
        final amount =
            (transaction['amount_232143'] as num?)?.toDouble() ?? (transaction['amount'] as num?)?.toDouble() ?? 0.0;
        final type =
            transaction['type_232143']?.toString().toLowerCase() ??
            transaction['type']?.toString().toLowerCase() ??
            'expense';

        String key;
        if (period == 'week' || period == 'month') {
          key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        } else {
          key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        }

        if (!dataByDate.containsKey(key)) {
          dataByDate[key] = {'income': 0, 'expense': 0};
        }

        if (type == 'income') {
          dataByDate[key]!['income'] = (dataByDate[key]!['income'] ?? 0) + amount;
        } else if (type == 'expense') {
          dataByDate[key]!['expense'] = (dataByDate[key]!['expense'] ?? 0) + amount;
        }
      } catch (e) {
        continue;
      }
    }

    // Convert to list and sort
    final result =
        dataByDate.entries.map((e) {
          return {'date': e.key, 'income': e.value['income'] ?? 0, 'expense': e.value['expense'] ?? 0};
        }).toList();

    result.sort((a, b) => a['date'].toString().compareTo(b['date'].toString()));
    return result;
  }

  List<Map<String, dynamic>> _getTopCategories(Map<String, double> categories, int limit) {
    final sorted = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) {
      return {'category': e.key, 'amount': e.value};
    }).toList();
  }

  Map<String, dynamic> _getPreviousPeriodComparison(
    List<Map<String, dynamic>> allTransactions,
    String period,
    DateTime now,
  ) {
    DateTime startDate;
    DateTime endDate;

    switch (period) {
      case 'week':
        endDate = now.subtract(const Duration(days: 7));
        startDate = endDate.subtract(const Duration(days: 7));
        break;
      case 'month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        startDate = lastMonth;
        endDate = DateTime(now.year, now.month, 0); // Last day of previous month
        break;
      case 'year':
        startDate = DateTime(now.year - 1, 1, 1);
        endDate = DateTime(now.year - 1, 12, 31);
        break;
      default:
        return {'totalIncome': 0, 'totalExpense': 0};
    }

    final previousTransactions =
        allTransactions.where((t) {
          try {
            final dateStr =
                t['transaction_date_232143']?.toString() ??
                t['transaction_date']?.toString() ??
                t['date']?.toString() ??
                '';
            final date = DateTime.parse(dateStr);
            return date.isAfter(startDate) && date.isBefore(endDate.add(const Duration(days: 1)));
          } catch (e) {
            return false;
          }
        }).toList();

    double totalIncome = 0;
    double totalExpense = 0;

    for (var transaction in previousTransactions) {
      final amount =
          (transaction['amount_232143'] as num?)?.toDouble() ?? (transaction['amount'] as num?)?.toDouble() ?? 0.0;
      final type =
          transaction['type_232143']?.toString().toLowerCase() ??
          transaction['type']?.toString().toLowerCase() ??
          'expense';

      if (type == 'income') {
        totalIncome += amount;
      } else if (type == 'expense') {
        totalExpense += amount;
      }
    }

    return {'totalIncome': totalIncome, 'totalExpense': totalExpense, 'savings': totalIncome - totalExpense};
  }

  /// Calculate percentage change from previous period
  double calculatePercentageChange(double current, double previous) {
    if (previous == 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  }
}
