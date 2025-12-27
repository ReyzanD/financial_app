import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/features/budgets/domain/entities/budget_entity.dart';
import 'package:financial_app/features/budgets/domain/repositories/budget_repository_interface.dart';

/// Budget Repository Implementation (Data Layer) - Now uses local database
class BudgetRepository implements BudgetRepositoryInterface {
  final ApiService _apiService = ApiService();

  @override
  Future<List<BudgetEntity>> getBudgets({bool activeOnly = false}) async {
    try {
      final budgets = await _apiService.getBudgets(activeOnly: activeOnly);
      return budgets.map((b) => BudgetEntity.fromJson(b as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BudgetEntity> createBudget(BudgetEntity budget) async {
    try {
      final result = await _apiService.createBudget(budget.toJson());
      return BudgetEntity.fromJson(result['budget'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BudgetEntity> updateBudget(BudgetEntity budget) async {
    try {
      final result = await _apiService.updateBudget(budget.id, budget.toJson());
      return BudgetEntity.fromJson(result['budget'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    try {
      await _apiService.deleteBudget(id);
    } catch (e) {
      rethrow;
    }
  }
}

