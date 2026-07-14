import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/data/goal_data_service.dart';
import 'package:financial_app/features/goals/domain/entities/goal_entity.dart';
import 'package:financial_app/features/goals/domain/repositories/goal_repository_interface.dart';

/// Goal Repository Implementation — wraps GoalDataService.
class GoalRepository implements GoalRepositoryInterface {
  final GoalDataService _goalData;

  GoalRepository({GoalDataService? goalData})
    : _goalData = goalData ?? getIt<GoalDataService>();

  @override
  Future<List<GoalEntity>> getGoals() async {
    final goals = await _goalData.getGoals();
    return goals.map((g) => GoalEntity.fromJson(g.toJson())).toList();
  }

  @override
  Future<GoalEntity> createGoal(GoalEntity goal) async {
    final saved = await _goalData.addGoal(goal.toJson());
    return GoalEntity.fromJson(saved.toJson());
  }

  @override
  Future<GoalEntity> updateGoal(GoalEntity goal) async {
    final updated = await _goalData.updateGoal(goal.id, goal.toJson());
    return GoalEntity.fromJson(updated.toJson());
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _goalData.deleteGoal(id);
  }

  @override
  Future<Map<String, dynamic>> getSummary() async {
    final goals = await _goalData.getGoals();
    double totalTarget = 0;
    double totalSaved = 0;
    int completedCount = 0;

    for (final g in goals) {
      totalTarget += g.targetAmount;
      totalSaved += g.currentAmount;
      if (g.isCompleted) completedCount++;
    }

    return {
      'total_target': totalTarget,
      'total_saved': totalSaved,
      'overall_progress':
          totalTarget > 0 ? (totalSaved / totalTarget) * 100 : 0,
      'goal_count': goals.length,
      'completed_count': completedCount,
    };
  }

  @override
  Future<Map<String, dynamic>> addContribution(
    String goalId,
    double amount, {
    String? accountId,
    String? note,
  }) async {
    return await _goalData.addGoalContribution(
      goalId,
      amount,
      accountId: accountId,
      note: note,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getContributions(String goalId) async {
    return await _goalData.getGoalContributions(goalId);
  }

  @override
  Future<double> getTotalContributions() async {
    return await _goalData.getTotalGoalContributions();
  }
}
