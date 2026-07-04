import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/services/spending_pattern_analyzer.dart';

void main() {
  group('SpendingPatternAnalyzer', () {
    late SpendingPatternAnalyzer analyzer;

    setUp(() {
      analyzer = SpendingPatternAnalyzer();
    });

    Map<String, dynamic> createTransaction({
      required String date,
      required double amount,
      required String type,
      String category = 'makanan',
      String description = 'test transaction',
    }) {
      return {
        'transaction_date': date,
        'amount': amount,
        'type': type,
        'category_name': category,
        'description': description,
      };
    }

    group('analyzeMultiPeriod', () {
      test('should return empty result for empty transactions', () {
        final result = analyzer.analyzeMultiPeriod(
          transactions: [],
          monthsToAnalyze: 3,
        );

        expect(result, isA<Map>());
        expect(result['months_analyzed'], 3);
      });

      test('should analyze transactions for current month', () {
        final now = DateTime.now();
        final transactions = [
          createTransaction(
            date: '${now.year}-${now.month.toString().padLeft(2, '0')}-05',
            amount: 50000,
            type: 'expense',
            category: 'makanan',
          ),
          createTransaction(
            date: '${now.year}-${now.month.toString().padLeft(2, '0')}-10',
            amount: 100000,
            type: 'expense',
            category: 'transportasi',
          ),
        ];

        final result = analyzer.analyzeMultiPeriod(
          transactions: transactions,
          monthsToAnalyze: 1,
        );

        expect(result['months_analyzed'], 1);
        expect(result['trends'], isA<Map>());
        expect(result['frequent_merchants'], isA<List>());
      });

      test('should calculate correct income and expense totals', () {
        final now = DateTime.now();
        final currentMonth =
            '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final transactions = [
          createTransaction(
            date: '$currentMonth-01',
            amount: 5000000,
            type: 'income',
            category: 'gaji',
          ),
          createTransaction(
            date: '$currentMonth-05',
            amount: 500000,
            type: 'expense',
            category: 'makanan',
          ),
          createTransaction(
            date: '$currentMonth-10',
            amount: 300000,
            type: 'expense',
            category: 'transportasi',
          ),
        ];

        final result = analyzer.analyzeMultiPeriod(
          transactions: transactions,
          monthsToAnalyze: 1,
        );

        final periodData = result['period_data'] as Map;
        final monthData = periodData[currentMonth] as Map;

        expect(monthData['income'], 5000000.0);
        expect(monthData['expense'], 800000.0);
        expect(monthData['transaction_count'], 3);
      });

      test('should calculate savings rate correctly', () {
        final now = DateTime.now();
        final currentMonth =
            '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final transactions = [
          createTransaction(
            date: '$currentMonth-01',
            amount: 10000000,
            type: 'income',
          ),
          createTransaction(
            date: '$currentMonth-05',
            amount: 3000000,
            type: 'expense',
          ),
        ];

        final result = analyzer.analyzeMultiPeriod(
          transactions: transactions,
          monthsToAnalyze: 1,
        );

        final periodData = result['period_data'] as Map;
        final monthData = periodData[currentMonth] as Map;

        // Savings rate = (10000000 - 3000000) / 10000000 * 100 = 70%
        expect(monthData['savings_rate'], 70.0);
      });

      test('should handle zero income gracefully', () {
        final now = DateTime.now();
        final currentMonth =
            '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final transactions = [
          createTransaction(
            date: '$currentMonth-05',
            amount: 500000,
            type: 'expense',
          ),
        ];

        final result = analyzer.analyzeMultiPeriod(
          transactions: transactions,
          monthsToAnalyze: 1,
        );

        final periodData = result['period_data'] as Map;
        final monthData = periodData[currentMonth] as Map;

        expect(monthData['savings_rate'], 0.0);
      });

      test('should identify category spending', () {
        final now = DateTime.now();
        final currentMonth =
            '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final transactions = [
          createTransaction(
            date: '$currentMonth-01',
            amount: 100000,
            type: 'expense',
            category: 'makanan',
          ),
          createTransaction(
            date: '$currentMonth-05',
            amount: 200000,
            type: 'expense',
            category: 'makanan',
          ),
          createTransaction(
            date: '$currentMonth-10',
            amount: 150000,
            type: 'expense',
            category: 'transportasi',
          ),
        ];

        final result = analyzer.analyzeMultiPeriod(
          transactions: transactions,
          monthsToAnalyze: 1,
        );

        final periodData = result['period_data'] as Map;
        final monthData = periodData[currentMonth] as Map;
        final categorySpending = monthData['category_spending'] as Map;

        expect(categorySpending['makanan'], 300000.0);
        expect(categorySpending['transportasi'], 150000.0);
      });

      test('should track day of week spending', () {
        final now = DateTime.now();
        final currentMonth =
            '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final transactions = [
          createTransaction(
            date: '$currentMonth-05',
            amount: 50000,
            type: 'expense',
          ),
        ];

        final result = analyzer.analyzeMultiPeriod(
          transactions: transactions,
          monthsToAnalyze: 1,
        );

        final periodData = result['period_data'] as Map;
        final monthData = periodData[currentMonth] as Map;
        final dayOfWeekSpending = monthData['day_of_week_spending'] as Map;

        expect(dayOfWeekSpending, isA<Map>());
      });

      test('should identify frequent merchants', () {
        final now = DateTime.now();
        final currentMonth =
            '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final transactions = List.generate(
          5,
          (index) => createTransaction(
            date: '$currentMonth-${(index + 1).toString().padLeft(2, '0')}',
            amount: 50000,
            type: 'expense',
            description: 'tokopedia pembelian online',
          ),
        );

        final result = analyzer.analyzeMultiPeriod(
          transactions: transactions,
          monthsToAnalyze: 1,
        );

        final merchants = result['frequent_merchants'] as List;
        expect(merchants.isNotEmpty, true);
        expect(merchants.first['frequency'], 5);
        expect(merchants.first['suggestion'], isNotNull);
      });

      test('should calculate expense trend with sufficient data', () {
        final now = DateTime.now();
        final transactions = <Map<String, dynamic>>[];

        // Create transactions for 3 months ago with high spending
        for (int i = 0; i < 3; i++) {
          final month = DateTime(now.year, now.month - 3, 1);
          final monthKey =
              '${month.year}-${month.month.toString().padLeft(2, '0')}';
          transactions.add(
            createTransaction(
              date: '$monthKey-05',
              amount: 2000000,
              type: 'expense',
            ),
          );
        }

        // Create transactions for 1 month ago with low spending
        for (int i = 0; i < 3; i++) {
          final month = DateTime(now.year, now.month - 1, 1);
          final monthKey =
              '${month.year}-${month.month.toString().padLeft(2, '0')}';
          transactions.add(
            createTransaction(
              date: '$monthKey-05',
              amount: 500000,
              type: 'expense',
            ),
          );
        }

        final result = analyzer.analyzeMultiPeriod(
          transactions: transactions,
          monthsToAnalyze: 3,
        );

        final trends = result['trends'] as Map;
        expect(trends['expense_trend'], isA<String>());
        expect(
          ['increasing', 'decreasing', 'stable'].contains(trends['expense_trend']),
          true,
        );
      });

      test('should return insufficient_data for trend with < 2 months', () {
        final now = DateTime.now();
        final currentMonth =
            '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final transactions = [
          createTransaction(
            date: '$currentMonth-05',
            amount: 500000,
            type: 'expense',
          ),
        ];

        final result = analyzer.analyzeMultiPeriod(
          transactions: transactions,
          monthsToAnalyze: 1,
        );

        final trends = result['trends'] as Map;
        expect(trends['expense_trend'], 'insufficient_data');
        expect(trends['income_trend'], 'insufficient_data');
      });

      test('should handle invalid date formats gracefully', () {
        final transactions = [
          {
            'transaction_date': 'invalid-date',
            'amount': 50000,
            'type': 'expense',
            'category_name': 'makanan',
          },
          {
            'amount': 100000,
            'type': 'expense',
            'category_name': 'transportasi',
          },
        ];

        final result = analyzer.analyzeMultiPeriod(
          transactions: transactions,
          monthsToAnalyze: 1,
        );

        expect(result, isA<Map>());
      });

      test('should track day-of-week patterns', () {
        final now = DateTime.now();
        final transactions = <Map<String, dynamic>>[];

        // Add transactions on different days
        for (int i = 0; i < 7; i++) {
          final date = DateTime(now.year, now.month, i + 1);
          final dateStr =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          transactions.add(
            createTransaction(
              date: dateStr,
              amount: 100000 * (i + 1),
              type: 'expense',
            ),
          );
        }

        final result = analyzer.analyzeMultiPeriod(
          transactions: transactions,
          monthsToAnalyze: 1,
        );

        final dayPatterns = result['day_of_week_patterns'] as Map;
        expect(dayPatterns['peak_day'], isNotNull);
        expect(dayPatterns['average_per_day'], greaterThan(0));
      });

      test('should calculate category correlations with enough data', () {
        final now = DateTime.now();
        final transactions = <Map<String, dynamic>>[];

        // Create correlated spending across 3 months
        for (int i = 0; i < 3; i++) {
          final month = DateTime(now.year, now.month - i, 1);
          final monthKey =
              '${month.year}-${month.month.toString().padLeft(2, '0')}';

          final multiplier = (i + 1).toDouble();
          transactions.add(
            createTransaction(
              date: '$monthKey-05',
              amount: 100000 * multiplier,
              type: 'expense',
              category: 'makanan',
            ),
          );
          transactions.add(
            createTransaction(
              date: '$monthKey-10',
              amount: 50000 * multiplier,
              type: 'expense',
              category: 'transportasi',
            ),
          );
        }

        final result = analyzer.analyzeMultiPeriod(
          transactions: transactions,
          monthsToAnalyze: 3,
        );

        final correlations = result['category_correlations'] as Map;
        expect(correlations, isA<Map>());
      });
    });

    group('detectAnomalies', () {
      test('should return empty list for empty transactions', () {
        final anomalies = analyzer.detectAnomalies(transactions: []);
        expect(anomalies, isEmpty);
      });

      test('should return empty list for transactions with insufficient data', () {
        final now = DateTime.now();
        final currentMonth =
            '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final transactions = [
          createTransaction(
            date: '$currentMonth-01',
            amount: 50000,
            type: 'expense',
          ),
          createTransaction(
            date: '$currentMonth-05',
            amount: 60000,
            type: 'expense',
          ),
        ];

        final anomalies = analyzer.detectAnomalies(transactions: transactions);
        expect(anomalies, isEmpty);
      });

      test('should detect unusually high spending', () {
        final now = DateTime.now();
        final currentMonth =
            '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final transactions = <Map<String, dynamic>>[];

        // Normal transactions
        for (int i = 0; i < 5; i++) {
          transactions.add(
            createTransaction(
              date: '$currentMonth-${(i + 1).toString().padLeft(2, '0')}',
              amount: 50000,
              type: 'expense',
              category: 'makanan',
            ),
          );
        }

        // Anomalous transaction (much higher than average)
        transactions.add(
          createTransaction(
            date: '$currentMonth-10',
            amount: 500000,
            type: 'expense',
            category: 'makanan',
            description: 'large feast dinner',
          ),
        );

        final anomalies = analyzer.detectAnomalies(transactions: transactions);
        expect(anomalies.isNotEmpty, true);
        expect(anomalies.first['category'], 'makanan');
      });
    });

    group('calculateBudgetHealthScore', () {
      test('should return score between 0 and 100', () {
        final now = DateTime.now();
        final currentMonth =
            '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final transactions = [
          createTransaction(
            date: '$currentMonth-01',
            amount: 5000000,
            type: 'income',
          ),
          createTransaction(
            date: '$currentMonth-05',
            amount: 3000000,
            type: 'expense',
          ),
        ];

        final result = analyzer.calculateBudgetHealthScore(
          transactions: transactions,
          monthlyIncome: 5000000,
          monthlyBudget: 4000000,
        );

        expect(result['score'], inInclusiveRange(0.0, 100.0));
        expect(result['grade'], isNotNull);
      });

      test('should give higher score for good spending habits', () {
        final now = DateTime.now();
        final currentMonth =
            '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final transactions = [
          createTransaction(
            date: '$currentMonth-01',
            amount: 10000000,
            type: 'income',
          ),
          createTransaction(
            date: '$currentMonth-05',
            amount: 2000000,
            type: 'expense',
            category: 'makanan',
          ),
          createTransaction(
            date: '$currentMonth-10',
            amount: 1000000,
            type: 'expense',
            category: 'transportasi',
          ),
        ];

        final goodResult = analyzer.calculateBudgetHealthScore(
          transactions: transactions,
          monthlyIncome: 10000000,
          monthlyBudget: 5000000,
        );

        // Low spending, high savings should give good score
        expect(goodResult['score'], greaterThan(50.0));
      });

      test('should include recommendations', () {
        final now = DateTime.now();
        final currentMonth =
            '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final transactions = [
          createTransaction(
            date: '$currentMonth-05',
            amount: 5000000,
            type: 'expense',
          ),
        ];

        final result = analyzer.calculateBudgetHealthScore(
          transactions: transactions,
          monthlyIncome: 5000000,
          monthlyBudget: 3000000,
        );

        expect(result['recommendations'], isA<List>());
        expect((result['recommendations'] as List).isNotEmpty, true);
      });
    });

    group('identifySavingsOpportunities', () {
      test('should return empty list for empty transactions', () {
        final opportunities = analyzer.identifySavingsOpportunities(
          transactions: [],
          monthlyIncome: 5000000,
        );
        expect(opportunities, isEmpty);
      });

      test('should identify opportunities for high spenders', () {
        final now = DateTime.now();
        final transactions = <Map<String, dynamic>>[];

        // Add transactions for last 3 months with high expenses
        for (int month = 0; month < 3; month++) {
          final monthDate = DateTime(now.year, now.month - month, 1);
          final monthKey =
              '${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}';

          for (int i = 0; i < 10; i++) {
            transactions.add(
              createTransaction(
                date: '$monthKey-${(i + 1).toString().padLeft(2, '0')}',
                amount: 500000,
                type: 'expense',
              ),
            );
          }
        }

        final opportunities = analyzer.identifySavingsOpportunities(
          transactions: transactions,
          monthlyIncome: 4000000, // Income lower than expenses
        );

        expect(opportunities.isNotEmpty, true);
      });

      test('should identify recurring expense categories', () {
        final now = DateTime.now();
        final currentMonth =
            '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final transactions = <Map<String, dynamic>>[];

        // Add frequent transactions in one category
        for (int i = 0; i < 5; i++) {
          transactions.add(
            createTransaction(
              date: '$currentMonth-${(i + 1).toString().padLeft(2, '0')}',
              amount: 100000,
              type: 'expense',
              category: 'hiburan',
            ),
          );
        }

        final opportunities = analyzer.identifySavingsOpportunities(
          transactions: transactions,
          monthlyIncome: 5000000,
        );

        // Should have at least one opportunity for the frequent category
        final hasReviewOpportunity = opportunities.any(
          (opp) => opp['type'] == 'review_recurring_expenses',
        );
        expect(hasReviewOpportunity, true);
      });
    });

    group('generateActionableInsights', () {
      test('should generate comprehensive insights', () {
        final now = DateTime.now();
        final currentMonth =
            '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final transactions = [
          createTransaction(
            date: '$currentMonth-01',
            amount: 10000000,
            type: 'income',
          ),
          createTransaction(
            date: '$currentMonth-05',
            amount: 3000000,
            type: 'expense',
            category: 'makanan',
          ),
          createTransaction(
            date: '$currentMonth-10',
            amount: 2000000,
            type: 'expense',
            category: 'transportasi',
          ),
        ];

        final insights = analyzer.generateActionableInsights(
          transactions: transactions,
          monthlyIncome: 10000000,
          monthlyBudget: 5000000,
        );

        expect(insights['overall_assessment'], isA<String>());
        expect(insights['health_score'], isA<Map>());
        expect(insights['action_items'], isA<List>());
      });

      test('should include total potential monthly savings', () {
        final now = DateTime.now();
        final currentMonth =
            '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final transactions = [
          createTransaction(
            date: '$currentMonth-05',
            amount: 5000000,
            type: 'expense',
          ),
        ];

        final insights = analyzer.generateActionableInsights(
          transactions: transactions,
          monthlyIncome: 5000000,
          monthlyBudget: 4000000,
        );

        expect(insights['total_potential_monthly_savings'], isA<double>());
      });
    });
  });
}
