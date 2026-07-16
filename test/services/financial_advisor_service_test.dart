import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:financial_app/models/goal_model.dart';
import 'package:financial_app/services/data/goal_data_service.dart';
import 'package:financial_app/services/financial_advisor_service.dart';
import 'package:financial_app/features/daad/presentation/screens/german_finance_screen.dart';

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

  group('FinancialAdvisorService getGoalRunRate (Phase F reuse)', () {
    GoalDataService? original;

    setUp(() {
      // Swap in an in-memory mock so no SQLite is touched.
      if (GetIt.instance.isRegistered<GoalDataService>()) {
        original = GetIt.instance<GoalDataService>();
        GetIt.instance.unregister<GoalDataService>();
      }
      GetIt.instance.registerLazySingleton<GoalDataService>(
        () => _MockGoalDataService(),
      );
    });

    tearDown(() {
      GetIt.instance.unregister<GoalDataService>();
      if (original != null) {
        GetIt.instance.registerLazySingleton<GoalDataService>(() => original!);
        original = null;
      }
    });

    test('finds Sperrkonto goal by name and returns its run-rate', () async {
      final service = FinancialAdvisorService();
      final rate = await service.getGoalRunRate('Sperrkonto');

      expect(rate, isNotNull);
      expect(rate!.name, 'Sperrkonto Studi Jerman');
      // 20,000,000 saved of 200,000,000 target → 10% progress.
      expect(rate.progressPercent, closeTo(10.0, 0.001));
      // Deadline 10 months out, remaining 180,000,000 → 18,000,000/month.
      expect(rate.monthlyContribution, closeTo(18000000, 0.001));
      expect(rate.monthsToGoal, 10);
    });

    test('returns null when no matching goal exists', () async {
      final service = FinancialAdvisorService();
      final rate = await service.getGoalRunRate('nonexistent');
      expect(rate, isNull);
    });
  });

  group('coverageMonths (Phase F Sperrkonto coverage tracker)', () {
    test('divides saved IDR by monthly EUR cap converted to IDR', () {
      // 11,904 EUR * 17,500 rate = 208,320,000 IDR required for 12 months.
      // 104,160,000 saved → exactly 6 months of coverage.
      expect(
        coverageMonths(
          savedIdr: 104160000,
          monthlyEurCap: 992,
          rateEurToIdr: 17500,
        ),
        closeTo(6.0, 0.001),
      );
    });

    test('returns 0 when rate or cap is non-positive', () {
      expect(
        coverageMonths(savedIdr: 100, monthlyEurCap: 0, rateEurToIdr: 17500),
        0,
      );
      expect(
        coverageMonths(savedIdr: 100, monthlyEurCap: 992, rateEurToIdr: 0),
        0,
      );
    });
  });
}

/// In-memory GoalDataService stub returning one Sperrkonto goal.
class _MockGoalDataService extends GoalDataService {
  @override
  Future<List<GoalModel>> getGoals() async {
    final now = DateTime.now();
    return [
      GoalModel(
        id: 'g1',
        userId: 'u1',
        name: 'Sperrkonto Studi Jerman',
        goalType: 'education',
        targetAmount: 200000000,
        currentAmount: 20000000,
        startDate: now,
        targetDate: now.add(const Duration(days: 305)),
        createdAt: now,
      ),
    ];
  }
}
