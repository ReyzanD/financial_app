import 'package:financial_app/features/goals/domain/entities/goal_entity.dart';
import 'package:financial_app/features/goals/domain/repositories/goal_repository_interface.dart';

/// Use case: create a new financial goal.
class CreateGoalUseCase {
  final GoalRepositoryInterface _repository;

  CreateGoalUseCase(this._repository);

  Future<GoalEntity> call(GoalEntity goal) => _repository.createGoal(goal);
}
