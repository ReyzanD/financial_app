import 'package:financial_app/services/api/budget_api.dart';
import 'package:financial_app/features/budgets/domain/entities/budget_entity.dart';
import 'package:financial_app/features/budgets/domain/repositories/budget_repository_interface.dart';

/// Budget Repository Implementation (Data Layer)
class BudgetRepository implements BudgetRepositoryInterface {
  @override
  Future<List<BudgetEntity>> getBudgets({bool activeOnly = false}) async {
    try {
      final budgets = await BudgetApi.getBudgets();
      // Filter active only if needed
      final filtered = activeOnly
          ? budgets.where((b) => (b as Map<String, dynamic>)['is_active'] == true).toList()
          : budgets;
      return filtered.map((b) => BudgetEntity.fromJson(b as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BudgetEntity> createBudget(BudgetEntity budget) async {
    try {
      final result = await BudgetApi.createBudget(budget.toJson());
      return BudgetEntity.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BudgetEntity> updateBudget(BudgetEntity budget) async {
    try {
      final result = await BudgetApi.updateBudget(budget.id, budget.toJson());
      return BudgetEntity.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    try {
      await BudgetApi.deleteBudget(id);
    } catch (e) {
      rethrow;
    }
  }
}

