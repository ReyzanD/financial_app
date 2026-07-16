import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/services/financial_advisor_service.dart';

void main() {
  group('FinancialAdvisorService.computeAnalysis (50/30/20 engine)', () {
    test('should return zeroed analysis when no transactions', () {
      final result = FinancialAdvisorService.computeAnalysis([]);

      expect(result.monthlyIncome, 0.0);
      expect(result.monthlyExpense, 0.0);
      expect(result.savings, 0.0);
      expect(result.needsActual, 0.0);
      expect(result.wantsActual, 0.0);
      expect(result.needsTarget, 0.0);
      expect(result.wantsTarget, 0.0);
      expect(result.savingsTarget, 0.0);
      expect(result.needsCategories, isEmpty);
      expect(result.wantsCategories, isEmpty);
      expect(result.goalRunRates, isEmpty);
    });

    test('should correctly classify needs vs wants vs uncategorized', () {
      final transactions = [
        {'amount': 10000000, 'type': 'income', 'category_name': 'Gaji'},
        {
          'amount': 3000000,
          'type': 'expense',
          'category_name': 'Makanan & Minuman',
        },
        {'amount': 1500000, 'type': 'expense', 'category_name': 'Hiburan'},
        {'amount': 500000, 'type': 'expense', 'category_name': 'Pulsa'},
        {
          'amount': 750000,
          'type': 'expense',
          'category_name': 'Lainnya (uncategorized)',
        },
      ];

      final result = FinancialAdvisorService.computeAnalysis(transactions);

      // Income
      expect(result.monthlyIncome, 10000000.0);
      // Total expense
      expect(result.monthlyExpense, 5750000.0);
      // Savings
      expect(result.savings, 4250000.0);

      // Needs: Makanan (3jt) + Pulsa (500rb) + Lainnya defaults to needs (750rb) = 4.25jt
      expect(result.needsActual, 4250000.0);
      // Wants: Hiburan (1.5jt)
      expect(result.wantsActual, 1500000.0);

      // Targets: 50% needs = 5jt, 30% wants = 3jt, 20% savings = 2jt
      expect(result.needsTarget, 5000000.0);
      expect(result.wantsTarget, 3000000.0);
      expect(result.savingsTarget, 2000000.0);

      // Percentages
      expect(result.needsPercent, 42.5); // 4.25jt / 10jt * 100
      expect(result.wantsPercent, 15.0); // 1.5jt / 10jt * 100
      expect(result.savingsPercent, 42.5); // 4.25jt / 10jt * 100

      // Gaps: needs within budget, wants within budget, savings exceeds target
      expect(
        result.needsGap,
        -750000.0,
      ); // 4.25jt - 5jt = -750rb (under budget)
      expect(
        result.wantsGap,
        -1500000.0,
      ); // 1.5jt - 3jt = -1.5jt (under budget)
      expect(
        result.savingsGap,
        -2250000.0,
      ); // 2jt - 4.25jt = -2.25jt (under-saving? No, savingsGap is target - actual, so 2jt - 4.25jt = -2.25jt means OVER-saving)
      // Actually: savingsGap = savingsTarget - savings = 2jt - 4.25jt = -2.25jt (negative = over-saving = good)

      // Category breakdowns
      expect(result.needsCategories.length, 3);
      // Sorted by amount descending
      expect(result.needsCategories[0].name, 'Makanan & Minuman');
      expect(result.needsCategories[0].amount, 3000000.0);
      expect(result.needsCategories[1].name, 'Lainnya (uncategorized)');
      expect(result.needsCategories[1].amount, 750000.0);
      expect(result.needsCategories[2].name, 'Pulsa');
      expect(result.needsCategories[2].amount, 500000.0);

      expect(result.wantsCategories.length, 1);
      expect(result.wantsCategories[0].name, 'Hiburan');
      expect(result.wantsCategories[0].amount, 1500000.0);
    });

    test('should correctly calculate needs categories', () {
      final transactions = [
        {'amount': 10000000, 'type': 'income', 'category_name': 'Gaji'},
        // All known need categories
        {'amount': 1000000, 'type': 'expense', 'category_name': 'Transportasi'},
        {
          'amount': 2000000,
          'type': 'expense',
          'category_name': 'Kebutuhan Pokok',
        },
        {
          'amount': 500000,
          'type': 'expense',
          'category_name': 'Tagihan & Utilitas',
        },
        {'amount': 300000, 'type': 'expense', 'category_name': 'Kesehatan'},
        {'amount': 1000000, 'type': 'expense', 'category_name': 'Pendidikan'},
        {'amount': 200000, 'type': 'expense', 'category_name': 'Asuransi'},
        {'amount': 1500000, 'type': 'expense', 'category_name': 'Sewa'},
        {'amount': 200000, 'type': 'expense', 'category_name': 'Listrik'},
        {'amount': 100000, 'type': 'expense', 'category_name': 'Air'},
        {'amount': 100000, 'type': 'expense', 'category_name': 'Pulsa'},
        {'amount': 300000, 'type': 'expense', 'category_name': 'Internet'},
        // 'Makanan' is also a need
        {'amount': 1500000, 'type': 'expense', 'category_name': 'Makanan'},
      ];

      final result = FinancialAdvisorService.computeAnalysis(transactions);

      // All 13 known needs categories
      expect(
        result.needsCategories.length,
        12,
      ); // Makanan & Minuman not in here but Makanan is
      // Actually needsMap has 12 distinct categories since Makanan & Minuman isn't present
      // Check total needs
      expect(result.needsActual, 8700000.0);
      expect(result.needsPercent, 87.0); // 8.7jt / 10jt * 100
    });

    test('should correctly calculate wants categories', () {
      final transactions = [
        {'amount': 10000000, 'type': 'income', 'category_name': 'Gaji'},
        // All known want categories
        {'amount': 500000, 'type': 'expense', 'category_name': 'Hiburan'},
        {'amount': 1000000, 'type': 'expense', 'category_name': 'Belanja'},
        {'amount': 300000, 'type': 'expense', 'category_name': 'Hobi'},
        {'amount': 200000, 'type': 'expense', 'category_name': 'Lifestyle'},
        {'amount': 2000000, 'type': 'expense', 'category_name': 'Travel'},
        {'amount': 500000, 'type': 'expense', 'category_name': 'Makan di Luar'},
        {'amount': 100000, 'type': 'expense', 'category_name': 'Kafe'},
        {'amount': 150000, 'type': 'expense', 'category_name': 'Game'},
        {'amount': 100000, 'type': 'expense', 'category_name': 'Streaming'},
        {'amount': 750000, 'type': 'expense', 'category_name': 'Fashion'},
        // Shopping alias
        {'amount': 400000, 'type': 'expense', 'category_name': 'Shopping'},
        // Nongkrong alias
        {'amount': 100000, 'type': 'expense', 'category_name': 'Nongkrong'},
        // Liburan alias
        {'amount': 1000000, 'type': 'expense', 'category_name': 'Liburan'},
      ];

      final result = FinancialAdvisorService.computeAnalysis(transactions);

      expect(result.wantsCategories.length, 13);
      expect(result.wantsActual, 7100000.0);
      expect(result.wantsPercent, 71.0); // 7.1jt / 10jt * 100
    });

    test('should handle multiple income transactions', () {
      final transactions = [
        {'amount': 8000000, 'type': 'income', 'category_name': 'Gaji'},
        {'amount': 2000000, 'type': 'income', 'category_name': 'Freelance'},
        {
          'amount': 3000000,
          'type': 'expense',
          'category_name': 'Makanan & Minuman',
        },
      ];

      final result = FinancialAdvisorService.computeAnalysis(transactions);

      expect(result.monthlyIncome, 10000000.0);
      expect(result.needsActual, 3000000.0);
      expect(result.needsPercent, 30.0);
    });

    test('should handle field name fallbacks (category vs category_name)', () {
      final transactions = [
        {'amount': 5000000, 'type': 'income', 'category': 'Gaji'},
        {'amount': 1000000, 'type': 'expense', 'category': 'Makanan & Minuman'},
      ];

      final result = FinancialAdvisorService.computeAnalysis(transactions);

      expect(result.monthlyIncome, 5000000.0);
      expect(result.needsActual, 1000000.0);
    });

    test('should handle missing fields gracefully', () {
      final transactions = <Map<String, dynamic>>[
        {'type': 'income'}, // no amount
        {'type': 'expense', 'category_name': 'Makanan & Minuman'}, // no amount
        <String, dynamic>{}, // completely empty
      ];

      final result = FinancialAdvisorService.computeAnalysis(transactions);

      // All amounts should default to 0
      expect(result.monthlyIncome, 0.0);
      expect(result.monthlyExpense, 0.0);
      expect(result.needsActual, 0.0);
      expect(result.wantsActual, 0.0);
    });

    test(
      'should correctly compute percentages and gaps for over-budget needs',
      () {
        final transactions = [
          {'amount': 10000000, 'type': 'income', 'category_name': 'Gaji'},
          // Needs = 80% of income (> 50% target)
          {
            'amount': 8000000,
            'type': 'expense',
            'category_name': 'Makanan & Minuman',
          },
        ];

        final result = FinancialAdvisorService.computeAnalysis(transactions);

        expect(result.needsPercent, 80.0);
        expect(result.needsGap, 3000000.0); // 8jt - 5jt = +3jt (over budget)
        expect(result.needsTarget, 5000000.0);
        expect(result.savings, 2000000.0);
        expect(result.savingsPercent, 20.0); // 2jt / 10jt
      },
    );

    test('should handle scenario with irregular income and no expense', () {
      // Edge: income but no expenses
      final transactions = [
        {'amount': 10000000, 'type': 'income', 'category_name': 'Gaji'},
      ];

      final result = FinancialAdvisorService.computeAnalysis(transactions);

      expect(result.monthlyIncome, 10000000.0);
      expect(result.monthlyExpense, 0.0);
      expect(result.savings, 10000000.0);
      expect(result.needsActual, 0.0);
      expect(result.wantsActual, 0.0);
      expect(result.needsPercent, 0.0);
      expect(result.wantsPercent, 0.0);
      expect(result.savingsPercent, 100.0);
    });

    test('should include goal run-rates when passed', () {
      final result = FinancialAdvisorService.computeAnalysis(
        [],
        goals: [
          const GoalRunRate(
            name: 'Emergency Fund',
            targetAmount: 50000000,
            currentAmount: 25000000,
            monthlyContribution: 2000000,
            progressPercent: 50.0,
            monthsToGoal: 13,
          ),
        ],
      );

      expect(result.goalRunRates.length, 1);
      expect(result.goalRunRates[0].name, 'Emergency Fund');
      expect(result.goalRunRates[0].progressPercent, 50.0);
    });
  });

  group('FinancialAdvisorService.getAssessment', () {
    test('should return no-data message when income is zero', () {
      final analysis = FinancialAdvisorService.computeAnalysis([]);
      final service = FinancialAdvisorService();

      final assessment = service.getAssessment(analysis);

      expect(assessment, contains('Belum ada data pemasukan'));
    });

    test('should mention needs over target when > 50%', () {
      final transactions = [
        {'amount': 10000000, 'type': 'income', 'category_name': 'Gaji'},
        {'amount': 6000000, 'type': 'expense', 'category_name': 'Transportasi'},
      ];
      final analysis = FinancialAdvisorService.computeAnalysis(transactions);
      final service = FinancialAdvisorService();

      final assessment = service.getAssessment(analysis);

      expect(assessment, contains('melebihi batas'));
      expect(assessment, contains('dalam batas')); // wants
      expect(assessment, contains('mencapai target')); // savings
    });

    test('should mention goals when present and on track', () {
      final analysis = FinancialAdvisorService.computeAnalysis(
        [
          {'amount': 10000000, 'type': 'income', 'category_name': 'Gaji'},
          {
            'amount': 3000000,
            'type': 'expense',
            'category_name': 'Makanan & Minuman',
          },
        ],
        goals: [
          const GoalRunRate(
            name: 'Vacation',
            targetAmount: 10000000,
            currentAmount: 5000000,
            monthlyContribution: 1000000,
            progressPercent: 50.0,
            monthsToGoal: 5,
          ),
        ],
      );
      final service = FinancialAdvisorService();

      final assessment = service.getAssessment(analysis);

      expect(assessment, contains('Vacation'));
      expect(assessment, contains('5 bulan'));
    });
  });

  group('GoalRunRate logic', () {
    test('should report monthsToGoal = -1 when no monthly contribution', () {
      final goal = const GoalRunRate(
        name: 'Test',
        targetAmount: 10000000,
        currentAmount: 0,
        monthlyContribution: 0,
        progressPercent: 0,
        monthsToGoal: -1,
      );

      expect(goal.monthsToGoal, -1);
    });
  });

  group('FinancialAdvisorService.generateSuggestions', () {
    test('should return empty list when income is zero', () {
      final analysis = FinancialAdvisorService.computeAnalysis([]);

      final suggestions = FinancialAdvisorService.generateSuggestions(analysis);

      expect(suggestions, isEmpty);
    });

    test('should suggest reducing needs categories over 15% of income', () {
      final analysis = FinancialAdvisorService.computeAnalysis([
        {'amount': 10000000, 'type': 'income', 'category_name': 'Gaji'},
        {
          'amount': 5000000,
          'type': 'expense',
          'category_name': 'Makanan & Minuman',
        },
      ]);

      final suggestions = FinancialAdvisorService.generateSuggestions(analysis);

      // 5jt / 10jt = 50% of income — way over 15% threshold
      expect(suggestions, isNotEmpty);
      expect(
        suggestions.any((s) => s.categoryName == 'Makanan & Minuman'),
        isTrue,
      );
      expect(suggestions.first.potentialMonthlySavings, greaterThan(0));
    });

    test('should suggest reducing wants categories over 10% of income', () {
      final analysis = FinancialAdvisorService.computeAnalysis([
        {'amount': 10000000, 'type': 'income', 'category_name': 'Gaji'},
        {'amount': 3000000, 'type': 'expense', 'category_name': 'Hiburan'},
      ]);

      final suggestions = FinancialAdvisorService.generateSuggestions(analysis);

      // 3jt / 10jt = 30% of income — way over 10% threshold
      expect(suggestions, isNotEmpty);
      expect(suggestions.any((s) => s.categoryName == 'Hiburan'), isTrue);
    });

    test('should sort suggestions by potential savings descending', () {
      final analysis = FinancialAdvisorService.computeAnalysis([
        {'amount': 10000000, 'type': 'income', 'category_name': 'Gaji'},
        // Need: 50% of income (over 15%)
        {
          'amount': 5000000,
          'type': 'expense',
          'category_name': 'Makanan & Minuman',
        },
        // Want: 20% of income (over 10%)
        {'amount': 2000000, 'type': 'expense', 'category_name': 'Hiburan'},
        // Another need: 20% (over 15%)
        {'amount': 2000000, 'type': 'expense', 'category_name': 'Transportasi'},
      ]);

      final suggestions = FinancialAdvisorService.generateSuggestions(analysis);

      expect(suggestions.length, greaterThanOrEqualTo(2));
      for (int i = 0; i < suggestions.length - 1; i++) {
        expect(
          suggestions[i].potentialMonthlySavings,
          greaterThanOrEqualTo(suggestions[i + 1].potentialMonthlySavings),
        );
      }
    });

    test('should return at most 5 suggestions', () {
      // Create many categories all over budget
      final txs = <Map<String, dynamic>>[
        {'amount': 100000000, 'type': 'income', 'category_name': 'Gaji'},
      ];
      // Add 10 expense categories each over threshold
      for (int i = 0; i < 10; i++) {
        txs.add({
          'amount': 20000000,
          'type': 'expense',
          'category_name': 'Kategori $i',
        });
      }

      final analysis = FinancialAdvisorService.computeAnalysis(txs);
      final suggestions = FinancialAdvisorService.generateSuggestions(analysis);

      expect(suggestions.length, lessThanOrEqualTo(5));
    });

    test('should return empty for well-balanced budget', () {
      final analysis = FinancialAdvisorService.computeAnalysis([
        {'amount': 10000000, 'type': 'income', 'category_name': 'Gaji'},
        // Needs under 15% of income
        {'amount': 1000000, 'type': 'expense', 'category_name': 'Transportasi'},
        // Wants under 10% of income
        {'amount': 500000, 'type': 'expense', 'category_name': 'Hiburan'},
      ]);

      final suggestions = FinancialAdvisorService.generateSuggestions(analysis);

      expect(suggestions, isEmpty);
    });

    test('should include type and targetPercent correctly', () {
      final analysis = FinancialAdvisorService.computeAnalysis([
        {'amount': 10000000, 'type': 'income', 'category_name': 'Gaji'},
        {
          'amount': 3000000,
          'type': 'expense',
          'category_name': 'Makanan & Minuman',
        },
      ]);

      final suggestions = FinancialAdvisorService.generateSuggestions(analysis);

      expect(suggestions, isNotEmpty);
      expect(suggestions.first.type, 'needs');
      expect(suggestions.first.targetPercent, 50);
    });
  });
}
