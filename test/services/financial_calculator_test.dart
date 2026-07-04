import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/services/financial_calculator.dart';

void main() {
  group('FinancialCalculator', () {
    late FinancialCalculator calculator;

    setUp(() {
      calculator = FinancialCalculator();
    });

    test('calculateBalance should return correct balance', () {
      final result = calculator.calculateBalance(
        income: 10000000,
        expenses: 7000000,
      );

      expect(result['balanceAmount'], 3000000.0);
      expect(result['isNegative'], false);
      expect(result['warning'], isNull);
    });

    test('calculateBalance should warn for negative balance', () {
      final result = calculator.calculateBalance(
        income: 5000000,
        expenses: 7000000,
      );

      expect(result['isNegative'], true);
      expect(result['warning'], isNotNull);
    });

    test('calculateSavingsRate should return correct percentage', () {
      final result = calculator.calculateSavingsRate(
        income: 10000000,
        expenses: 7000000,
      );

      expect(result, 30.0);
    });

    test('calculateSavingsRate should return 0 for zero income', () {
      final result = calculator.calculateSavingsRate(
        income: 0,
        expenses: 7000000,
      );

      expect(result, 0.0);
    });

    test('calculateFinancialHealthScore should return score between 0-100', () {
      final result = calculator.calculateFinancialHealthScore(
        income: 10000000,
        expenses: 7000000,
        savings: 3000000,
      );

      expect(result['score'], inInclusiveRange(0.0, 100.0));
      expect(result['level'], isNotNull);
    });

    test('calculateFinancialHealthScore should give higher score for good habits', () {
      final goodHabits = calculator.calculateFinancialHealthScore(
        income: 10000000,
        expenses: 3000000,
        savings: 7000000,
        debtAmount: 0,
        budgetTotal: 5000000,
        budgetSpent: 3000000,
      );

      final badHabits = calculator.calculateFinancialHealthScore(
        income: 10000000,
        expenses: 9500000,
        savings: 500000,
        debtAmount: 5000000,
      );

      expect(goodHabits['score'], greaterThan(badHabits['score']));
    });

    test('calculateProgressiveTax should return 0 for zero income', () {
      final result = calculator.calculateProgressiveTax(0);
      expect(result, 0.0);
    });

    test('calculateProgressiveTax should calculate 5% for income under 50M', () {
      final result = calculator.calculateProgressiveTax(10000000);
      expect(result, 500000.0);
    });

    test('calculateMonthComparison should return changes', () {
      final result = calculator.calculateMonthComparison(
        currentIncome: 12000000,
        currentExpenses: 8000000,
        previousIncome: 10000000,
        previousExpenses: 7000000,
      );

      expect(result['changes']['income']['percent'], 20.0);
      expect(result['trends']['income'], 'up');
    });

    test('calculateRunningBalance should track cumulative balance', () {
      final transactions = [
        {'date': '2025-01-01', 'amount': 10000000.0, 'type': 'income'},
        {'date': '2025-01-05', 'amount': 3000000.0, 'type': 'expense'},
      ];

      final result = calculator.calculateRunningBalance(transactions: transactions);

      expect(result.length, 2);
      expect(result[0]['runningBalanceValue'], 10000000.0);
      expect(result[1]['runningBalanceValue'], 7000000.0);
    });

    test('calculateBalanceProjection should project positive balance', () {
      final result = calculator.calculateBalanceProjection(
        currentBalance: 10000000,
        averageMonthlyIncome: 10000000,
        averageMonthlyExpenses: 7000000,
        months: 3,
      );

      expect(result['isPositive'], true);
      expect(result['projectedBalanceAmount'], 19000000.0);
    });

    test('getIndonesiaDefaultRates should return inflation and tax rates', () {
      final result = calculator.getIndonesiaDefaultRates();
      expect(result['inflationRate'], 3.5);
      expect(result['taxRate'], 15.0);
    });

    test('calculateExpenseBreakdown should group by category', () {
      final expenses = [
        {'category': 'Makanan', 'amount': 500000.0},
        {'category': 'Makanan', 'amount': 300000.0},
        {'category': 'Transport', 'amount': 200000.0},
      ];

      final result = calculator.calculateExpenseBreakdown(expenses: expenses);

      expect(result.length, 2);
    });
  });
}
