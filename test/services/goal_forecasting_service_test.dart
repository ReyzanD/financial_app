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
  });
}
