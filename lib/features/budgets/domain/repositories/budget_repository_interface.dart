import 'package:financial_app/features/budgets/domain/entities/budget_entity.dart';

/// Budget Repository Interface (Domain Layer)
abstract class BudgetRepositoryInterface {
  Future<List<BudgetEntity>> getBudgets({bool activeOnly = false});
  Future<BudgetEntity> createBudget(BudgetEntity budget);
  Future<BudgetEntity> updateBudget(BudgetEntity budget);
  Future<void> deleteBudget(String id);
}

