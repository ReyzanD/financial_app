import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/services/goal_forecasting_service.dart';

void main() {
  group('GoalForecastingService', () {
    late GoalForecastingService service;

    setUp(() {
      service = GoalForecastingService();
    });

    test('should return 0 months if goal is already completed', () {
      final result = service.forecastGoalCompletion(
        targetAmount: 1000000,
        currentAmount: 1500000,
        monthlyContribution: 100000,
      );

      expect(result['monthsToCompletion'], 0);
      expect(result['onTrack'], true);
      expect(result['confidence'], 1.0);
    });

    test('should calculate months to completion', () {
      final result = service.forecastGoalCompletion(
        targetAmount: 1000000,
        currentAmount: 200000,
        monthlyContribution: 100000,
      );

      expect(result['monthsToCompletion'], 8);
      expect(result['onTrack'], true);
    });

    test('should return warning if no contributions', () {
      final result = service.forecastGoalCompletion(
        targetAmount: 1000000,
        currentAmount: 200000,
        monthlyContribution: 0,
      );

      expect(result['monthsToCompletion'], -1);
      expect(result['onTrack'], false);
      expect(result['warning'], isNotNull);
    });

    test('should analyze historical contributions trend', () {
      final result = service.forecastGoalCompletion(
        targetAmount: 1000000,
        currentAmount: 500000,
        monthlyContribution: 100000,
        historicalContributions: [
          {'date': '2025-01-01', 'amount': 50000.0},
          {'date': '2025-02-01', 'amount': 60000.0},
          {'date': '2025-03-01', 'amount': 70000.0},
          {'date': '2025-04-01', 'amount': 80000.0},
          {'date': '2025-05-01', 'amount': 90000.0},
          {'date': '2025-06-01', 'amount': 100000.0},
        ],
      );

      expect(result['monthsToCompletion'], greaterThan(0));
      expect(result['trend'], greaterThan(0));
    });

    test('should detect declining contribution trend', () {
      final result = service.forecastGoalCompletion(
        targetAmount: 1000000,
        currentAmount: 500000,
        monthlyContribution: 50000,
        historicalContributions: [
          {'date': '2025-01-01', 'amount': 200000.0},
          {'date': '2025-02-01', 'amount': 180000.0},
          {'date': '2025-03-01', 'amount': 50000.0},
          {'date': '2025-04-01', 'amount': 30000.0},
        ],
      );

      expect(result['trend'], lessThan(0));
    });

    test('should return warning for long completion time', () {
      final result = service.forecastGoalCompletion(
        targetAmount: 100000000,
        currentAmount: 1000000,
        monthlyContribution: 100000,
      );

      expect(result['warning'], isNotNull);
    });

    test('should generate correct milestones', () {
      final milestones = service.generateMilestones(
        targetAmount: 1000000,
        monthsToCompletion: 12,
      );

      expect(milestones.length, 4);
      expect(milestones[0]['percentage'], 0.25);
      expect(milestones[1]['percentage'], 0.5);
      expect(milestones[2]['percentage'], 0.75);
      expect(milestones[3]['percentage'], 1.0);
    });

    test('milestone labels should be in Bahasa Indonesia', () {
      final milestones = service.generateMilestones(
        targetAmount: 1000000,
        monthsToCompletion: 12,
      );

      expect(milestones[0]['label'].contains('%'), true);
      expect(milestones[3]['label'].contains('Target tercapai'), true);
    });

    test('should handle null historical contributions gracefully', () {
      final result = service.forecastGoalCompletion(
        targetAmount: 1000000,
        currentAmount: 200000,
        monthlyContribution: 100000,
        historicalContributions: null,
      );

      expect(result['monthsToCompletion'], greaterThan(0));
      expect(result['confidence'], 0.7);
    });

    test('completion date uses real month arithmetic (no *30 drift)', () {
      // Freeze "now" by checking the offset is exactly monthsToCompletion months.
      final result = service.forecastGoalCompletion(
        targetAmount: 1000000,
        currentAmount: 200000,
        monthlyContribution: 100000, // 8 months to completion
      );

      final completionStr = result['completionDate'] as String?;
      expect(completionStr, isNotNull);
      final completion = DateTime.tryParse(completionStr!);
      expect(completion, isNotNull);
      // 8 months from now must not be 8*30=240 days (which would drift).
      final now = DateTime.now();
      final expected = DateTime(now.year, now.month + 8, now.day);
      expect(completion!.year, expected.year);
      expect(completion.month, expected.month);
      expect(completion.day, expected.day);
      // Sanity: must NOT equal now + 240 days (the old buggy behaviour).
      final buggy = now.add(const Duration(days: 240));
      expect(
        completion.day == buggy.day && completion.month == buggy.month,
        isFalse,
      );
    });

    test('milestone dates use real month arithmetic', () {
      final milestones = service.generateMilestones(
        targetAmount: 1000000,
        monthsToCompletion: 12,
      );

      final now = DateTime.now();
      // Last milestone (100%) should be exactly 12 months from now.
      final lastDate = DateTime.tryParse(milestones.last['date'] as String);
      expect(lastDate, isNotNull);
      final expected = DateTime(now.year, now.month + 12, now.day);
      expect(lastDate!.year, expected.year);
      expect(lastDate.month, expected.month);
      expect(lastDate.day, expected.day);
    });
  });
}
