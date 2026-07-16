import 'dart:math' as math;
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/account_service.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';
import 'package:financial_app/core/di/service_locator.dart';

class CashFlowForecastService {
  final TransactionDataService _transactionData;
  final AccountService _accountService;

  CashFlowForecastService({
    TransactionDataService? transactionData,
    AccountService? accountService,
  }) : _transactionData = transactionData ?? getIt<TransactionDataService>(),
       _accountService = accountService ?? getIt<AccountService>();

  Future<List<Map<String, dynamic>>> forecastDailyCashFlow({
    int days = 30,
  }) async {
    try {
      final now = DateTime.now();
      final transactions = await _transactionData.getAllTransactions();

      final dailyData = _analyzeDailyPatterns(transactions);
      final forecast = <Map<String, dynamic>>[];

      double runningBalance = await _accountService.getTotalBalance();

      for (int i = 1; i <= days; i++) {
        final forecastDate = now.add(Duration(days: i));
        final dayOfWeek = forecastDate.weekday;

        final avgIncome =
            dailyData['income_by_weekday']?[dayOfWeek]?.toDouble() ?? 0.0;
        final avgExpense =
            dailyData['expense_by_weekday']?[dayOfWeek]?.toDouble() ?? 0.0;

        runningBalance += avgIncome - avgExpense;

        forecast.add({
          'date': forecastDate,
          'projected_income': avgIncome,
          'projected_expense': avgExpense,
          'projected_balance': runningBalance,
          'is_weekend': dayOfWeek >= 6,
          'confidence': _calculateConfidence(i, dailyData),
        });
      }

      return forecast;
    } catch (e) {
      LoggerService.error('Error forecasting daily cash flow', error: e);
      return [];
    }
  }

  Future<Map<String, dynamic>> getWeeklyCashFlowForecast({
    int weeks = 4,
  }) async {
    try {
      final now = DateTime.now();
      final transactions = await _transactionData.getAllTransactions();

      final weeklyData = _analyzeWeeklyPatterns(transactions);
      double runningBalance = await _accountService.getTotalBalance();

      final forecast = <Map<String, dynamic>>[];

      for (int i = 1; i <= weeks; i++) {
        final weekStart = now.add(Duration(days: i * 7));

        final avgIncome = weeklyData['avg_weekly_income']?.toDouble() ?? 0.0;
        final avgExpense = weeklyData['avg_weekly_expense']?.toDouble() ?? 0.0;

        runningBalance += avgIncome - avgExpense;

        forecast.add({
          'week_start': weekStart,
          'week_end': weekStart.add(const Duration(days: 6)),
          'projected_income': avgIncome,
          'projected_expense': avgExpense,
          'projected_balance': runningBalance,
          'net_cash_flow': avgIncome - avgExpense,
        });
      }

      final riskWeeks =
          forecast
              .where((w) => (w['projected_balance'] as double) < 0)
              .toList();

      return {
        'weekly_forecast': forecast,
        'risk_weeks': riskWeeks.length,
        'lowest_balance':
            forecast.isNotEmpty
                ? forecast
                    .map((w) => w['projected_balance'] as double)
                    .reduce(math.min)
                : 0.0,
        'highest_balance':
            forecast.isNotEmpty
                ? forecast
                    .map((w) => w['projected_balance'] as double)
                    .reduce(math.max)
                : 0.0,
      };
    } catch (e) {
      LoggerService.error('Error getting weekly cash flow forecast', error: e);
      return {'weekly_forecast': [], 'risk_weeks': 0};
    }
  }

  Future<Map<String, dynamic>> getCashFlowSummary() async {
    try {
      final transactions = await _transactionData.getAllTransactions();
      final now = DateTime.now();

      double currentIncome = 0;
      double currentExpense = 0;
      double previousIncome = 0;
      double previousExpense = 0;

      for (var t in transactions) {
        final dateStr =
            t['transaction_date_232143']?.toString() ??
            t['transaction_date']?.toString() ??
            '';
        if (dateStr.isEmpty) continue;

        final date = DateTime.parse(dateStr);
        final type =
            t['type_232143']?.toString() ?? t['type']?.toString() ?? '';
        final amount =
            (t['amount_232143'] as num?)?.toDouble() ??
            (t['amount'] as num?)?.toDouble() ??
            0.0;

        final isCurrentMonth = date.year == now.year && date.month == now.month;
        final prevMonth = DateTime(now.year, now.month - 1, 1);
        final isPreviousMonth =
            date.year == prevMonth.year && date.month == prevMonth.month;

        if (isCurrentMonth) {
          if (type == 'income') currentIncome += amount;
          if (type == 'expense') currentExpense += amount;
        } else if (isPreviousMonth) {
          if (type == 'income') previousIncome += amount;
          if (type == 'expense') previousExpense += amount;
        }
      }

      return {
        'current_month_income': currentIncome,
        'current_month_expense': currentExpense,
        'current_month_net': currentIncome - currentExpense,
        'previous_month_income': previousIncome,
        'previous_month_expense': previousExpense,
        'previous_month_net': previousIncome - previousExpense,
        'income_change':
            previousIncome > 0
                ? ((currentIncome - previousIncome) / previousIncome) * 100
                : 0,
        'expense_change':
            previousExpense > 0
                ? ((currentExpense - previousExpense) / previousExpense) * 100
                : 0,
      };
    } catch (e) {
      LoggerService.error('Error getting cash flow summary', error: e);
      return {};
    }
  }

  Map<String, dynamic> _analyzeDailyPatterns(
    List<Map<String, dynamic>> transactions,
  ) {
    final incomeByWeekday = <int, double>{};
    final expenseByWeekday = <int, double>{};
    final weekdayCounts = <int, int>{};

    for (final transaction in transactions) {
      final dateStr =
          transaction['transaction_date_232143']?.toString() ??
          transaction['transaction_date']?.toString() ??
          '';
      if (dateStr.isEmpty) continue;

      try {
        final date = DateTime.parse(dateStr);
        final weekday = date.weekday;
        final amount =
            (transaction['amount_232143'] as num?)?.toDouble() ??
            (transaction['amount'] as num?)?.toDouble() ??
            0.0;
        final type =
            transaction['type_232143']?.toString() ??
            transaction['type']?.toString() ??
            '';

        weekdayCounts[weekday] = (weekdayCounts[weekday] ?? 0) + 1;

        if (type == 'income') {
          incomeByWeekday[weekday] = (incomeByWeekday[weekday] ?? 0) + amount;
        } else if (type == 'expense') {
          expenseByWeekday[weekday] = (expenseByWeekday[weekday] ?? 0) + amount;
        }
      } catch (e) {
        // Skip invalid dates
      }
    }

    for (var weekday in incomeByWeekday.keys) {
      final count = weekdayCounts[weekday] ?? 1;
      incomeByWeekday[weekday] = incomeByWeekday[weekday]! / count;
    }
    for (var weekday in expenseByWeekday.keys) {
      final count = weekdayCounts[weekday] ?? 1;
      expenseByWeekday[weekday] = expenseByWeekday[weekday]! / count;
    }

    return {
      'income_by_weekday': incomeByWeekday,
      'expense_by_weekday': expenseByWeekday,
    };
  }

  Map<String, dynamic> _analyzeWeeklyPatterns(
    List<Map<String, dynamic>> transactions,
  ) {
    final now = DateTime.now();
    final weeklyIncome = <double>[];
    final weeklyExpense = <double>[];

    for (int week = 0; week < 8; week++) {
      final weekStart = now.subtract(Duration(days: (week + 1) * 7));
      final weekEnd = now.subtract(Duration(days: week * 7));

      double weekIncome = 0;
      double weekExpense = 0;

      for (final transaction in transactions) {
        final dateStr =
            transaction['transaction_date_232143']?.toString() ??
            transaction['transaction_date']?.toString() ??
            '';
        if (dateStr.isEmpty) continue;

        try {
          final date = DateTime.parse(dateStr);
          if (date.isAfter(weekStart) && date.isBefore(weekEnd)) {
            final amount =
                (transaction['amount_232143'] as num?)?.toDouble() ??
                (transaction['amount'] as num?)?.toDouble() ??
                0.0;
            final type =
                transaction['type_232143']?.toString() ??
                transaction['type']?.toString() ??
                '';

            if (type == 'income') weekIncome += amount;
            if (type == 'expense') weekExpense += amount;
          }
        } catch (e) {
          // Skip
        }
      }

      if (weekIncome > 0) weeklyIncome.add(weekIncome);
      if (weekExpense > 0) weeklyExpense.add(weekExpense);
    }

    return {
      'avg_weekly_income':
          weeklyIncome.isNotEmpty
              ? weeklyIncome.reduce((a, b) => a + b) / weeklyIncome.length
              : 0.0,
      'avg_weekly_expense':
          weeklyExpense.isNotEmpty
              ? weeklyExpense.reduce((a, b) => a + b) / weeklyExpense.length
              : 0.0,
    };
  }

  double _calculateConfidence(int daysAhead, Map<String, dynamic> dailyData) {
    final baseConfidence = 1.0;
    final decayRate = 0.02;
    return baseConfidence * math.exp(-decayRate * daysAhead);
  }
}
