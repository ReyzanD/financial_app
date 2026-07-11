import 'package:financial_app/features/goals/domain/repositories/goal_repository_interface.dart';

/// Use case: delete a financial goal by id.
class DeleteGoalUseCase {
  final GoalRepositoryInterface _repository;

  DeleteGoalUseCase(this._repository);

  Future<void> call(String id) => _repository.deleteGoal(id);
}
