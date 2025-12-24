import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/services/financial_calculator.dart';

void main() {
  group('FinancialCalculator', () {
    late FinancialCalculator calculator;

    setUp(() {
      calculator = FinancialCalculator();
    });

    group('calculateBalance', () {
      test('should calculate positive balance when income > expenses', () {
        final result = calculator.calculateBalance(
          income: 1000000,
          expenses: 500000,
        );

        expect(result['balanceAmount'], equals(500000.0));
        expect(result['isNegative'], isFalse);
      });

      test('should calculate negative balance when expenses > income', () {
        final result = calculator.calculateBalance(
          income: 500000,
          expenses: 1000000,
        );

        expect(result['balanceAmount'], equals(-500000.0));
        expect(result['isNegative'], isTrue);
        expect(result['warning'], isNotNull);
      });

      test('should handle zero income and expenses', () {
        final result = calculator.calculateBalance(
          income: 0,
          expenses: 0,
        );

        expect(result['balanceAmount'], equals(0.0));
        expect(result['isNegative'], isFalse);
      });
    });

    group('calculateSavingsRate', () {
      test('should calculate correct savings rate', () {
        final rate = calculator.calculateSavingsRate(
          income: 1000000,
          expenses: 700000,
        );

        expect(rate, equals(30.0));
      });

      test('should return 0 when income is 0', () {
        final rate = calculator.calculateSavingsRate(
          income: 0,
          expenses: 500000,
        );

        expect(rate, equals(0.0));
      });

      test('should return negative rate when expenses exceed income', () {
        final rate = calculator.calculateSavingsRate(
          income: 500000,
          expenses: 800000,
        );

        expect(rate, lessThan(0));
      });
    });

    group('calculateFinancialHealthScore', () {
      test('should return high score for healthy finances', () {
        final result = calculator.calculateFinancialHealthScore(
          income: 10000000,
          expenses: 5000000,
          savings: 5000000,
          inflationRate: 3.5,
          taxRate: 15.0,
        );

        expect(result['score'], greaterThan(80));
        expect(result['level'], isNotNull);
      });

      test('should return low score for poor finances', () {
        final result = calculator.calculateFinancialHealthScore(
          income: 1000000,
          expenses: 1200000,
          savings: -200000,
          inflationRate: 3.5,
          taxRate: 15.0,
        );

        expect(result['score'], lessThan(50));
        expect(result['level'], isNotNull);
      });
    });
  });
}

