import 'package:financial_app/services/data/goal_data_service.dart';
import 'package:financial_app/features/goals/domain/entities/goal_entity.dart';
import 'package:financial_app/features/goals/domain/repositories/goal_repository_interface.dart';

/// Goal Repository Implementation — wraps GoalDataService.
class GoalRepository implements GoalRepositoryInterface {
  final GoalDataService _goalData;

  GoalRepository({GoalDataService? goalData})
    : _goalData = goalData ?? GoalDataService();

  @override
  Future<List<GoalEntity>> getGoals() async {
    final goals = await _goalData.getGoals();
    return goals.map((g) => GoalEntity.fromJson(g)).toList();
  }

  @override
  Future<GoalEntity> createGoal(GoalEntity goal) async {
    final result = await _goalData.addGoal(goal.toJson());
    final saved = result['goal'] as Map<String, dynamic>? ?? result;
    return GoalEntity.fromJson(saved);
  }

  @override
  Future<GoalEntity> updateGoal(GoalEntity goal) async {
    await _goalData.updateGoal(goal.id, goal.toJson());
    // Re-fetch the goal after update (updateGoal only returns success status)
    final allGoals = await _goalData.getGoals();
    final updated = allGoals.firstWhere(
      (g) => g['goal_id_232143']?.toString() == goal.id,
      orElse: () => goal.toJson(),
    );
    return GoalEntity.fromJson(updated);
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
      final target =
          (g['target_amount_232143'] ?? g['target_amount'] as num?)
              ?.toDouble() ??
          0;
      final current =
          (g['current_amount_232143'] ?? g['current_amount'] as num?)
              ?.toDouble() ??
          0;
      totalTarget += target;
      totalSaved += current;
      if ((g['is_completed_232143'] as num?) == 1) completedCount++;
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
