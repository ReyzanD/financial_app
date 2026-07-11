import 'package:financial_app/features/budgets/domain/entities/budget_entity.dart';
import 'package:financial_app/features/budgets/domain/repositories/budget_repository_interface.dart';

/// Use Case: Get Budgets
class GetBudgetsUseCase {
  final BudgetRepositoryInterface _repository;

  GetBudgetsUseCase(this._repository);

  Future<List<BudgetEntity>> call({bool activeOnly = false}) async {
    return await _repository.getBudgets(activeOnly: activeOnly);
  }
}
