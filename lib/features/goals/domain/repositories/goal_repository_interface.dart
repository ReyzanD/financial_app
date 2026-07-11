import 'package:financial_app/features/goals/domain/entities/goal_entity.dart';

/// Abstract repository for Goal data operations.
abstract class GoalRepositoryInterface {
  Future<List<GoalEntity>> getGoals();
  Future<GoalEntity> createGoal(GoalEntity goal);
  Future<GoalEntity> updateGoal(GoalEntity goal);
  Future<void> deleteGoal(String id);
  Future<Map<String, dynamic>> getSummary();
  Future<Map<String, dynamic>> addContribution(
      String goalId, double amount, {String? accountId, String? note});
  Future<List<Map<String, dynamic>>> getContributions(String goalId);
  Future<double> getTotalContributions();
}
