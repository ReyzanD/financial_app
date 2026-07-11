import 'package:financial_app/features/budgets/domain/entities/budget_entity.dart';
import 'package:financial_app/features/budgets/domain/repositories/budget_repository_interface.dart';

/// Use Case: Update Budget
class UpdateBudgetUseCase {
  final BudgetRepositoryInterface _repository;

  UpdateBudgetUseCase(this._repository);

  Future<BudgetEntity> call(BudgetEntity budget) async {
    return await _repository.updateBudget(budget);
  }
}
