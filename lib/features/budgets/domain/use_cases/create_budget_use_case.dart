import 'package:financial_app/features/budgets/domain/entities/budget_entity.dart';
import 'package:financial_app/features/budgets/domain/repositories/budget_repository_interface.dart';

/// Use Case: Create Budget
class CreateBudgetUseCase {
  final BudgetRepositoryInterface _repository;

  CreateBudgetUseCase(this._repository);

  Future<BudgetEntity> call(BudgetEntity budget) async {
    if (budget.amount <= 0) {
      throw Exception('Budget amount must be greater than 0');
    }
    return await _repository.createBudget(budget);
  }
}
