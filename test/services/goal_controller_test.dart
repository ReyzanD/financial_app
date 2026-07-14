import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/features/goals/presentation/controllers/goal_controller.dart';
import 'package:financial_app/features/goals/data/repositories/goal_repository.dart';
import 'package:financial_app/services/data/goal_data_service.dart';

void main() {
  group('GoalController initial state', () {
    late GoalController controller;

    setUp(() {
      controller = GoalController(
        repository: GoalRepository(goalData: GoalDataService()),
      );
    });

    test('should return empty list when _goals is null before loadData', () {
      final goals = controller.goals;
      expect(goals, isA<List>());
      expect(goals, isEmpty);
    });

    test('should return empty map when _summary is null before loadData', () {
      final summary = controller.summary;
      expect(summary, isA<Map<String, dynamic>>());
      expect(summary, isEmpty);
    });

    test('should have default loading state', () {
      expect(controller.isLoading, false);
    });

    test('should have null error before any operation', () {
      expect(controller.errorMessage, null);
    });

    test('should not throw when accessing summary fields on empty state', () {
      final summary = controller.summary;
      expect(summary['total_target'], null);
      expect(summary['total_saved'], null);
      expect(summary['overall_progress'], null);
    });
  });
}
