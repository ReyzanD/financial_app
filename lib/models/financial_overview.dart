import 'package:money2/money2.dart';

/// Unified data model for financial overview
/// Contains all financial metrics in one place
class FinancialOverview {
  final Money balance;
  final double savingsRate;
  final double healthScore;
  final String healthLevel;
  final Map<String, Money> expenseBreakdown;
  final Map<String, Money> incomeBreakdown;
  final Map<String, dynamic>? forecast;
  final List<Map<String, dynamic>>? recommendations;
  final Map<String, dynamic>? budgetStatus;
  final Money? afterTaxIncome;
  final Money? realSavings;
  final DateTime timestamp;

  FinancialOverview({
    required this.balance,
    required this.savingsRate,
    required this.healthScore,
    required this.healthLevel,
    required this.expenseBreakdown,
    required this.incomeBreakdown,
    this.forecast,
    this.recommendations,
    this.budgetStatus,
    this.afterTaxIncome,
    this.realSavings,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convert to JSON for storage/caching
  Map<String, dynamic> toJson() {
    return {
      'balance': balance.minorUnits.toInt(),
      'savingsRate': savingsRate,
      'healthScore': healthScore,
      'healthLevel': healthLevel,
      'expenseBreakdown': expenseBreakdown.map(
        (key, value) => MapEntry(key, value.minorUnits.toInt()),
      ),
      'incomeBreakdown': incomeBreakdown.map(
        (key, value) => MapEntry(key, value.minorUnits.toInt()),
      ),
      'forecast': forecast,
      'recommendations': recommendations,
      'budgetStatus': budgetStatus,
      'afterTaxIncome': afterTaxIncome?.minorUnits.toInt(),
      'realSavings': realSavings?.minorUnits.toInt(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON (for cache retrieval)
  factory FinancialOverview.fromJson(Map<String, dynamic> json) {
    return FinancialOverview(
      balance: Money.fromInt(
        json['balance'] as int? ?? 0,
        isoCode: 'IDR',
      ),
      savingsRate: (json['savingsRate'] as num?)?.toDouble() ?? 0.0,
      healthScore: (json['healthScore'] as num?)?.toDouble() ?? 0.0,
      healthLevel: json['healthLevel'] as String? ?? 'Needs Improvement',
      expenseBreakdown: (json['expenseBreakdown'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(
          key,
          Money.fromInt(value as int? ?? 0, isoCode: 'IDR'),
        ),
      ),
      incomeBreakdown: (json['incomeBreakdown'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(
          key,
          Money.fromInt(value as int? ?? 0, isoCode: 'IDR'),
        ),
      ),
      forecast: json['forecast'] as Map<String, dynamic>?,
      recommendations: json['recommendations'] as List<Map<String, dynamic>>?,
      budgetStatus: json['budgetStatus'] as Map<String, dynamic>?,
      afterTaxIncome: json['afterTaxIncome'] != null
          ? Money.fromInt(json['afterTaxIncome'] as int, isoCode: 'IDR')
          : null,
      realSavings: json['realSavings'] != null
          ? Money.fromInt(json['realSavings'] as int, isoCode: 'IDR')
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }
}

