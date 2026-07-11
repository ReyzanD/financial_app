import 'package:financial_app/features/budgets/domain/repositories/budget_repository_interface.dart';

/// Use Case: Delete Budget
class DeleteBudgetUseCase {
  final BudgetRepositoryInterface _repository;

  DeleteBudgetUseCase(this._repository);

  Future<void> call(String id) async {
    return await _repository.deleteBudget(id);
  }
}
