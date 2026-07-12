import 'dart:async';
import 'package:financial_app/services/data/budget_data_service.dart';
import 'package:financial_app/services/data/category_data_service.dart';
import 'package:financial_app/features/budgets/domain/entities/budget_entity.dart';
import 'package:financial_app/features/budgets/domain/repositories/budget_repository_interface.dart';

/// Budget Repository Implementation (Data Layer) - Uses local database directly.
class BudgetRepository implements BudgetRepositoryInterface {
  final BudgetDataService _budgetData;
  final CategoryDataService _categoryData;

  BudgetRepository({
    BudgetDataService? budgetData,
    CategoryDataService? categoryData,
  }) : _budgetData = budgetData ?? BudgetDataService(),
       _categoryData = categoryData ?? CategoryDataService();

  @override
  Future<List<BudgetEntity>> getBudgets({bool activeOnly = false}) async {
    try {
      final budgets = await _budgetData.getBudgets(activeOnly: activeOnly);
      return budgets.map((b) => BudgetEntity.fromJson(b)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BudgetEntity> createBudget(BudgetEntity budget) async {
    try {
      final result = await _budgetData.addBudget(budget.toJson());
      final saved = result['budget'] as Map<String, dynamic>? ?? result;
      return BudgetEntity.fromJson(saved);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BudgetEntity> updateBudget(BudgetEntity budget) async {
    try {
      final result = await _budgetData.updateBudget(budget.id, budget.toJson());
      final saved = result['budget'] as Map<String, dynamic>? ?? result;
      return BudgetEntity.fromJson(saved);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    try {
      await _budgetData.deleteBudget(id);
    } catch (e) {
      rethrow;
    }
  }

  /// Get budget summary stats.
  Future<Map<String, dynamic>> getSummary({bool activeOnly = false}) async {
    try {
      final budgets = await _budgetData.getBudgets(activeOnly: activeOnly);
      double totalBudgeted = 0;
      double totalSpent = 0;
      int activeCount = 0;

      for (final b in budgets) {
        totalBudgeted += (b['amount_232143'] as num?)?.toDouble() ?? 0;
        totalSpent += (b['spent_amount_232143'] as num?)?.toDouble() ?? 0;
        if ((b['is_active_232143'] as int? ?? 1) == 1) activeCount++;
      }

      return {
        'total_budgeted': totalBudgeted,
        'total_spent': totalSpent,
        'remaining': totalBudgeted - totalSpent,
        'usage_percentage':
            totalBudgeted > 0 ? (totalSpent / totalBudgeted) * 100 : 0,
        'active_budgets': activeCount,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Get categories for display mapping.
  Future<List<Map<String, dynamic>>> getCategories() async {
    return await _categoryData.getCategories();
  }
}
