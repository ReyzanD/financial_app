import 'dart:math' as math;
import 'package:money2/money2.dart';
import 'package:financial_app/services/logger_service.dart';

/// Service untuk financial calculations dengan precise currency handling
/// Menggunakan Money objects untuk menghindari floating-point errors
class FinancialCalculator {
  // IDR Currency definition
  static final Currency idr = Currency.create('IDR', 0, symbol: 'Rp ', pattern: '#,###');

  // Singleton pattern
  static final FinancialCalculator _instance = FinancialCalculator._internal();
  factory FinancialCalculator() => _instance;
  FinancialCalculator._internal();

  /// Convert dynamic value to Money object
  /// Handles int, double, Money, and num types
  Money _toMoney(dynamic value) {
    if (value is Money) {
      return value;
    } else if (value is int) {
      return Money.fromInt(value, isoCode: 'IDR');
    } else if (value is double || value is num) {
      // Convert double to int (cents/smallest unit)
      // For IDR, no decimal places, so multiply by 1
      final intValue = (value as num).round();
      return Money.fromInt(intValue, isoCode: 'IDR');
    } else {
      throw ArgumentError('Cannot convert ${value.runtimeType} to Money');
    }
  }

  /// Convert Money to int for storage
  /// Note: Currently unused but kept for future use
  // int _toInt(Money money) {
  //   return money.minorUnits.toInt();
  // }

  /// Convert Money to double (for backward compatibility)
  double _toDouble(Money money) {
    return money.minorUnits.toDouble();
  }
  
  /// Check if Money is negative
  bool _isNegative(Money money) {
    return money.minorUnits < BigInt.zero;
  }
  
  /// Check if Money is positive
  bool _isPositive(Money money) {
    return money.minorUnits > BigInt.zero;
  }

  /// Calculate balance (income - expenses)
  /// Returns balance amount and warning if negative
  /// Uses Money objects internally for precision
  Map<String, dynamic> calculateBalance({
    required double income,
    required double expenses,
  }) {
    final incomeMoney = _toMoney(income);
    final expensesMoney = _toMoney(expenses);
    final balanceMoney = incomeMoney - expensesMoney;
    final isNegative = _isNegative(balanceMoney);
    final warning = isNegative
        ? 'Saldo Anda negatif. Perhatikan pengeluaran Anda.'
        : null;

    LoggerService.debug(
      '[FinancialCalculator] Balance calculated: ${balanceMoney.toString()} (Income: ${incomeMoney.toString()}, Expenses: ${expensesMoney.toString()})',
    );

    return {
      'balance': balanceMoney, // Return Money object
      'balanceAmount': _toDouble(balanceMoney), // For backward compatibility
      'income': incomeMoney,
      'incomeAmount': _toDouble(incomeMoney),
      'expenses': expensesMoney,
      'expensesAmount': _toDouble(expensesMoney),
      'isNegative': isNegative,
      'warning': warning,
    };
  }

  /// Calculate savings rate (savings / income * 100)
  /// Returns percentage as double
  double calculateSavingsRate({
    required double income,
    required double expenses,
  }) {
    final incomeMoney = _toMoney(income);
    final expensesMoney = _toMoney(expenses);
    
    if (incomeMoney.minorUnits <= BigInt.zero) {
      LoggerService.warning('[FinancialCalculator] Income is zero or negative');
      return 0.0;
    }

    final savingsMoney = incomeMoney - expensesMoney;
    // Calculate percentage: (savings / income) * 100
    final rate = (savingsMoney.minorUnits.toDouble() / incomeMoney.minorUnits.toDouble()) * 100;
    LoggerService.debug('[FinancialCalculator] Savings rate: ${rate.toStringAsFixed(2)}%');
    return rate;
  }

  /// Calculate financial health score (0-100)
  /// Based on multiple factors: savings rate, budget adherence, debt ratio, etc.
  /// Now includes inflation and tax considerations
  Map<String, dynamic> calculateFinancialHealthScore({
    required double income,
    required double expenses,
    required double savings,
    double? debtAmount,
    double? budgetSpent,
    double? budgetTotal,
    double? inflationRate,
    double? taxRate,
  }) {
    final incomeMoney = _toMoney(income);
    final savingsMoney = _toMoney(savings);
    
    // Apply inflation and tax if provided
    final effectiveInflationRate = inflationRate ?? 0.0;
    final effectiveTaxRate = taxRate ?? 0.0;
    
    // After-tax income
    final afterTaxIncome = effectiveTaxRate > 0
        ? incomeMoney * (1 - effectiveTaxRate / 100)
        : incomeMoney;
    
    // Real savings (adjusted for inflation)
    final realSavings = effectiveInflationRate > 0
        ? savingsMoney / (1 + effectiveInflationRate / 100)
        : savingsMoney;
    
    double score = 0.0;
    final factors = <String, double>{};
    final recommendations = <String>[];

    // Factor 1: Savings Rate (40 points) - using after-tax income
    if (afterTaxIncome.minorUnits > BigInt.zero) {
      final savingsRate = (realSavings.minorUnits.toDouble() / afterTaxIncome.minorUnits.toDouble()) * 100;
      final savingsScore = (savingsRate / 20).clamp(0.0, 40.0); // 20% = perfect score
      score += savingsScore;
      factors['Savings Rate'] = savingsScore;
      
      if (savingsRate < 10) {
        recommendations.add('Tingkatkan tabungan Anda. Target minimal 10% dari pendapatan.');
      }
    }

    // Factor 2: Budget Adherence (30 points)
    if (budgetTotal != null && budgetTotal > 0) {
      final budgetTotalMoney = _toMoney(budgetTotal);
      final budgetSpentMoney = _toMoney(budgetSpent ?? expenses);
      final budgetRatio = budgetSpentMoney.minorUnits.toDouble() / budgetTotalMoney.minorUnits.toDouble();
      final budgetScore = (1 - budgetRatio.clamp(0.0, 1.0)) * 30;
      score += budgetScore;
      factors['Budget Adherence'] = budgetScore;
      
      if (budgetRatio > 0.9) {
        recommendations.add('Anda hampir melebihi budget. Perhatikan pengeluaran.');
      }
    } else {
      // No budget set, give neutral score
      score += 15;
      factors['Budget Adherence'] = 15.0;
      recommendations.add('Buat budget untuk mengontrol pengeluaran.');
    }

    // Factor 3: Debt Ratio (20 points)
    if (debtAmount != null && debtAmount > 0 && afterTaxIncome.minorUnits > BigInt.zero) {
      final debtMoney = _toMoney(debtAmount);
      final debtRatio = (debtMoney.minorUnits.toDouble() / afterTaxIncome.minorUnits.toDouble()) * 100;
      final debtScore = (1 - (debtRatio / 50).clamp(0.0, 1.0)) * 20;
      score += debtScore;
      factors['Debt Ratio'] = debtScore;
      
      if (debtRatio > 30) {
        recommendations.add('Rasio utang Anda tinggi. Pertimbangkan untuk mengurangi utang.');
      }
    } else {
      // No debt, give full score
      score += 20;
      factors['Debt Ratio'] = 20.0;
    }

    // Factor 4: Expense Stability (10 points)
    // This would require historical data, for now give neutral score
    score += 5;
    factors['Expense Stability'] = 5.0;

    final finalScore = score.clamp(0.0, 100.0);
    final healthLevel = _getHealthLevel(finalScore);

    LoggerService.debug(
      '[FinancialCalculator] Financial health score: $finalScore ($healthLevel)',
    );

    return {
      'score': finalScore,
      'level': healthLevel,
      'factors': factors,
      'recommendations': recommendations,
      'afterTaxIncome': afterTaxIncome,
      'afterTaxIncomeAmount': _toDouble(afterTaxIncome),
      'realSavings': realSavings,
      'realSavingsAmount': _toDouble(realSavings),
    };
  }

  /// Get health level based on score
  String _getHealthLevel(double score) {
    if (score >= 80) {
      return 'Excellent';
    } else if (score >= 60) {
      return 'Good';
    } else if (score >= 40) {
      return 'Fair';
    } else {
      return 'Needs Improvement';
    }
  }

  /// Get Indonesia default rates (inflation and tax)
  Map<String, double> getIndonesiaDefaultRates() {
    return {
      'inflationRate': 3.5,
      'taxRate': 15.0, // Average tax rate (progressive brackets: 5%, 15%, 25%, 30%, 35%)
    };
  }

  /// Calculate progressive tax for Indonesia
  /// Tax brackets: 0-50M: 5%, 50M-250M: 15%, 250M-500M: 25%, 500M-5B: 30%, >5B: 35%
  double calculateProgressiveTax(double income) {
    final incomeMoney = _toMoney(income);
    final incomeAmount = incomeMoney.minorUnits.toDouble();
    
    if (incomeAmount <= 0) return 0.0;
    
    double tax = 0.0;
    
    // 0-50M: 5%
    if (incomeAmount > 50000000) {
      tax += 50000000 * 0.05;
    } else {
      return incomeAmount * 0.05;
    }
    
    // 50M-250M: 15%
    if (incomeAmount > 250000000) {
      tax += (250000000 - 50000000) * 0.15;
    } else {
      return tax + (incomeAmount - 50000000) * 0.15;
    }
    
    // 250M-500M: 25%
    if (incomeAmount > 500000000) {
      tax += (500000000 - 250000000) * 0.25;
    } else {
      return tax + (incomeAmount - 250000000) * 0.25;
    }
    
    // 500M-5B: 30%
    if (incomeAmount > 5000000000) {
      tax += (5000000000 - 500000000) * 0.30;
    } else {
      return tax + (incomeAmount - 500000000) * 0.30;
    }
    
    // >5B: 35%
    tax += (incomeAmount - 5000000000) * 0.35;
    
    return tax;
  }

  /// Calculate month-over-month comparison
  /// Returns Money objects in the result
  Map<String, dynamic> calculateMonthComparison({
    required double currentIncome,
    required double currentExpenses,
    required double previousIncome,
    required double previousExpenses,
  }) {
    final currentIncomeMoney = _toMoney(currentIncome);
    final currentExpensesMoney = _toMoney(currentExpenses);
    final previousIncomeMoney = _toMoney(previousIncome);
    final previousExpensesMoney = _toMoney(previousExpenses);
    
    final currentBalanceMoney = currentIncomeMoney - currentExpensesMoney;
    final previousBalanceMoney = previousIncomeMoney - previousExpensesMoney;

    final incomeChangeMoney = currentIncomeMoney - previousIncomeMoney;
    final expenseChangeMoney = currentExpensesMoney - previousExpensesMoney;
    final balanceChangeMoney = currentBalanceMoney - previousBalanceMoney;

    final incomeChangePercent = previousIncomeMoney.minorUnits > BigInt.zero
        ? (incomeChangeMoney.minorUnits.toDouble() / previousIncomeMoney.minorUnits.toDouble()) * 100
        : 0.0;
    final expenseChangePercent = previousExpensesMoney.minorUnits > BigInt.zero
        ? (expenseChangeMoney.minorUnits.toDouble() / previousExpensesMoney.minorUnits.toDouble()) * 100
        : 0.0;
    final balanceChangePercent = previousBalanceMoney.minorUnits != BigInt.zero
        ? (balanceChangeMoney.minorUnits.toDouble() / previousBalanceMoney.minorUnits.abs().toDouble()) * 100
        : 0.0;

    LoggerService.debug(
      '[FinancialCalculator] Month comparison calculated',
    );

    return {
      'current': {
        'income': currentIncomeMoney,
        'incomeAmount': _toDouble(currentIncomeMoney),
        'expenses': currentExpensesMoney,
        'expensesAmount': _toDouble(currentExpensesMoney),
        'balance': currentBalanceMoney,
        'balanceAmount': _toDouble(currentBalanceMoney),
      },
      'previous': {
        'income': previousIncomeMoney,
        'incomeAmount': _toDouble(previousIncomeMoney),
        'expenses': previousExpensesMoney,
        'expensesAmount': _toDouble(previousExpensesMoney),
        'balance': previousBalanceMoney,
        'balanceAmount': _toDouble(previousBalanceMoney),
      },
      'changes': {
        'income': {
          'amount': incomeChangeMoney,
          'amountValue': _toDouble(incomeChangeMoney),
          'percent': incomeChangePercent,
        },
        'expenses': {
          'amount': expenseChangeMoney,
          'amountValue': _toDouble(expenseChangeMoney),
          'percent': expenseChangePercent,
        },
        'balance': {
          'amount': balanceChangeMoney,
          'amountValue': _toDouble(balanceChangeMoney),
          'percent': balanceChangePercent,
        },
      },
      'trends': {
        'income': _isPositive(incomeChangeMoney) ? 'up' : _isNegative(incomeChangeMoney) ? 'down' : 'stable',
        'expenses': _isPositive(expenseChangeMoney) ? 'up' : _isNegative(expenseChangeMoney) ? 'down' : 'stable',
        'balance': _isPositive(balanceChangeMoney) ? 'up' : _isNegative(balanceChangeMoney) ? 'down' : 'stable',
      },
    };
  }

  /// Calculate running balance (cumulative balance over time)
  /// Returns Money objects in running balances
  List<Map<String, dynamic>> calculateRunningBalance({
    required List<Map<String, dynamic>> transactions,
  }) {
    Money runningBalanceMoney = Money.fromInt(0, isoCode: 'IDR');
    final runningBalances = <Map<String, dynamic>>[];

    for (final transaction in transactions) {
      final amount = _toMoney(transaction['amount']);
      final type = transaction['type'] as String;

      if (type == 'income') {
        runningBalanceMoney = runningBalanceMoney + amount;
      } else if (type == 'expense') {
        runningBalanceMoney = runningBalanceMoney - amount;
      }

      runningBalances.add({
        'date': transaction['date'],
        'amount': amount,
        'amountValue': _toDouble(amount),
        'type': type,
        'runningBalance': runningBalanceMoney,
        'runningBalanceValue': _toDouble(runningBalanceMoney),
      });
    }

    LoggerService.debug(
      '[FinancialCalculator] Running balance calculated for ${transactions.length} transactions',
    );

    return runningBalances;
  }

  /// Calculate balance projection (future balance based on current trends)
  /// Now includes inflation adjustment
  Map<String, dynamic> calculateBalanceProjection({
    required double currentBalance,
    required double averageMonthlyIncome,
    required double averageMonthlyExpenses,
    required int months,
    double? inflationRate,
  }) {
    final currentBalanceMoney = _toMoney(currentBalance);
    final avgIncomeMoney = _toMoney(averageMonthlyIncome);
    final avgExpensesMoney = _toMoney(averageMonthlyExpenses);
    
    final monthlyChangeMoney = avgIncomeMoney - avgExpensesMoney;
    final effectiveInflationRate = inflationRate ?? 0.0;
    
    // Apply inflation to monthly change
    Money projectedBalanceMoney;
    if (effectiveInflationRate > 0) {
      // Apply inflation: monthlyChange * (1 + inflationRate/100)^months
      final inflationMultiplier = math.pow(1 + effectiveInflationRate / 100, months);
      final adjustedMonthlyChange = monthlyChangeMoney * inflationMultiplier;
      projectedBalanceMoney = currentBalanceMoney + (adjustedMonthlyChange * months);
    } else {
      projectedBalanceMoney = currentBalanceMoney + (monthlyChangeMoney * months);
    }
    
    final isPositive = !projectedBalanceMoney.isNegative;

    LoggerService.debug(
      '[FinancialCalculator] Balance projection: ${projectedBalanceMoney.toString()} in $months months',
    );

    return {
      'currentBalance': currentBalanceMoney,
      'currentBalanceAmount': _toDouble(currentBalanceMoney),
      'projectedBalance': projectedBalanceMoney,
      'projectedBalanceAmount': _toDouble(projectedBalanceMoney),
      'monthlyChange': monthlyChangeMoney,
      'monthlyChangeAmount': _toDouble(monthlyChangeMoney),
      'months': months,
      'isPositive': isPositive,
      'warning': isPositive
          ? null
          : 'Proyeksi saldo negatif dalam $months bulan. Perhatikan pengeluaran.',
      'inflationRate': effectiveInflationRate,
    };
  }

  /// Calculate expense breakdown by category
  /// Returns Money objects per category
  Map<String, Money> calculateExpenseBreakdown({
    required List<Map<String, dynamic>> expenses,
  }) {
    final breakdown = <String, Money>{};

    for (final expense in expenses) {
      final category = expense['category'] as String? ?? 'Uncategorized';
      final amountMoney = _toMoney(expense['amount']);

      breakdown[category] = (breakdown[category] ?? Money.fromInt(0, isoCode: 'IDR')) + amountMoney;
    }

    LoggerService.debug(
      '[FinancialCalculator] Expense breakdown calculated for ${breakdown.length} categories',
    );

    return breakdown;
  }

  /// Calculate income breakdown by category
  /// Returns Money objects per category
  Map<String, Money> calculateIncomeBreakdown({
    required List<Map<String, dynamic>> incomes,
  }) {
    final breakdown = <String, Money>{};

    for (final income in incomes) {
      final category = income['category'] as String? ?? 'Uncategorized';
      final amountMoney = _toMoney(income['amount']);

      breakdown[category] = (breakdown[category] ?? Money.fromInt(0, isoCode: 'IDR')) + amountMoney;
    }

    LoggerService.debug(
      '[FinancialCalculator] Income breakdown calculated for ${breakdown.length} categories',
    );

    return breakdown;
  }
}
