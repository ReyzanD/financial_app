import 'package:financial_app/features/goals/domain/entities/goal_entity.dart';
import 'package:financial_app/features/goals/domain/repositories/goal_repository_interface.dart';

/// Use case: retrieve all goals for the current user.
class GetGoalsUseCase {
  final GoalRepositoryInterface _repository;

  GetGoalsUseCase(this._repository);

  Future<List<GoalEntity>> call() => _repository.getGoals();
}
