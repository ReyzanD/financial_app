import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/services/financial_advisor_service.dart';

Map<String, dynamic> _tx({
  required double amount,
  required String type,
  required String category,
}) => {'amount_232143': amount, 'type_232143': type, 'category_name': category};

void main() {
  group('FinancialAdvisorService zero-based', () {
    test('computes income - expense = unallocated (surplus)', () {
      final txs = [
        _tx(amount: 10000000, type: 'income', category: 'Gaji'),
        _tx(amount: 3000000, type: 'expense', category: 'Makanan & Minuman'),
        _tx(amount: 1000000, type: 'expense', category: 'Hiburan'),
      ];

      final z = FinancialAdvisorService.computeZeroBased(txs);

      expect(z.monthlyIncome, 10000000);
      expect(z.monthlyExpense, 4000000);
      expect(z.unallocated, 6000000); // surplus
      expect(z.allocations.length, 2);
      // Sorted by amount desc: Makanan first
      expect(z.allocations.first.name, 'Makanan & Minuman');
      expect(z.allocations.first.percentOfIncome, 30.0);
    });

    test('computes shortfall when expenses exceed income', () {
      final txs = [
        _tx(amount: 5000000, type: 'income', category: 'Gaji'),
        _tx(amount: 7000000, type: 'expense', category: 'Sewa'),
      ];

      final z = FinancialAdvisorService.computeZeroBased(txs);

      expect(z.unallocated, -2000000);
      expect(z.allocations.first.name, 'Sewa');
    });
  });

  group('FinancialAdvisorService goal run-rate', () {
    test('monthsBetween counts whole months', () {
      expect(
        FinancialAdvisorService.monthsBetween(
          DateTime(2026, 1, 15),
          DateTime(2026, 4, 15),
        ),
        3,
      );
      expect(
        FinancialAdvisorService.monthsBetween(
          DateTime(2026, 1, 15),
          DateTime(2026, 1, 10),
        ),
        0,
      );
    });
  });

  group('FinancialAdvisorService 50/30/20', () {
    test('classifies needs vs wants and computes gaps', () {
      final txs = [
        _tx(amount: 10000000, type: 'income', category: 'Gaji'),
        _tx(
          amount: 6000000,
          type: 'expense',
          category: 'Makanan & Minuman',
        ), // needs, over 50%
        _tx(
          amount: 1000000,
          type: 'expense',
          category: 'Hiburan',
        ), // wants, within 30%
      ];

      final a = FinancialAdvisorService.computeAnalysis(txs);

      expect(a.needsActual, 6000000);
      expect(a.wantsActual, 1000000);
      expect(a.needsTarget, 5000000);
      expect(a.needsGap, 1000000); // over budget
      expect(a.savingsPercent, 30.0); // (10M-7M)/10M*100 = 30
    });

    test('uncategorized expense defaults to needs', () {
      final txs = [
        _tx(amount: 5000000, type: 'income', category: 'Gaji'),
        _tx(amount: 1000000, type: 'expense', category: 'Lainnya'),
      ];

      final a = FinancialAdvisorService.computeAnalysis(txs);
      expect(a.needsActual, 1000000);
      expect(a.wantsActual, 0);
    });
  });
}
