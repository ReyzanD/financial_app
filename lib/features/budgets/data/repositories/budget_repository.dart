import 'dart:async';
import 'package:financial_app/models/budget_model.dart';
import 'package:financial_app/models/category_model.dart';
import 'package:financial_app/services/data/budget_data_service.dart';
import 'package:financial_app/services/data/category_data_service.dart';
import 'package:financial_app/core/di/service_locator.dart';

/// Budget Repository - delegates to BudgetDataService, adds cross-cutting logic.
class BudgetRepository {
  final BudgetDataService _budgetData;
  final CategoryDataService _categoryData;

  BudgetRepository({
    BudgetDataService? budgetData,
    CategoryDataService? categoryData,
  }) : _budgetData = budgetData ?? getIt<BudgetDataService>(),
       _categoryData = categoryData ?? getIt<CategoryDataService>();

  Future<List<BudgetModel>> getBudgets({bool activeOnly = false}) async {
    return await _budgetData.getBudgets(activeOnly: activeOnly);
  }

  Future<BudgetModel> createBudget(BudgetModel budget) async {
    return await _budgetData.addBudget(budget.toJson());
  }

  Future<BudgetModel?> updateBudget(BudgetModel budget) async {
    return await _budgetData.updateBudget(budget.id, budget.toJson());
  }

  Future<bool> deleteBudget(String id) async {
    return await _budgetData.deleteBudget(id);
  }

  /// Get budget summary stats.
  Future<Map<String, dynamic>> getSummary({bool activeOnly = false}) async {
    final budgets = await _budgetData.getBudgets(activeOnly: activeOnly);
    double totalBudgeted = 0;
    double totalSpent = 0;
    int activeCount = 0;

    for (final b in budgets) {
      totalBudgeted += b.amount;
      totalSpent += b.spent;
      if (b.isActive) activeCount++;
    }

    return {
      'total_budgeted': totalBudgeted,
      'total_spent': totalSpent,
      'remaining': totalBudgeted - totalSpent,
      'usage_percentage':
          totalBudgeted > 0 ? (totalSpent / totalBudgeted) * 100 : 0,
      'active_budgets': activeCount,
    };
  }

  /// Get categories for display mapping.
  Future<List<CategoryModel>> getCategories() async {
    return await _categoryData.getCategories();
  }
}
