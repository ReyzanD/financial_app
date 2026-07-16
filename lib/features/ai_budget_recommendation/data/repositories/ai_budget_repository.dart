import 'dart:async';
import 'package:financial_app/services/budget_recommendation_service.dart';
import 'package:financial_app/services/data/category_data_service.dart';
import 'package:financial_app/services/data/budget_data_service.dart';
import 'package:financial_app/core/di/service_locator.dart';

/// AI Budget Recommendation Repository - delegates to the underlying services.
class AIBudgetRepository {
  final CategoryDataService _categoryData;
  final BudgetDataService _budgetData;
  final BudgetRecommendationService _budgetService;

  AIBudgetRepository({
    CategoryDataService? categoryData,
    BudgetDataService? budgetData,
    BudgetRecommendationService? budgetService,
  })  : _categoryData = categoryData ?? getIt<CategoryDataService>(),
        _budgetData = budgetData ?? getIt<BudgetDataService>(),
        _budgetService = budgetService ?? getIt<BudgetRecommendationService>();

  Future<Map<String, dynamic>> generateRecommendation() async {
    return await _budgetService.generateRecommendation();
  }

  Future<List<dynamic>> getCategories() async {
    return await _categoryData.getCategories();
  }

  Future<List<dynamic>> getBudgets({bool activeOnly = false}) async {
    return await _budgetData.getBudgets(activeOnly: activeOnly);
  }

  Future<dynamic> updateBudget(String id, Map<String, dynamic> data) async {
    return await _budgetData.updateBudget(id, data);
  }

  Future<dynamic> addBudget(Map<String, dynamic> data) async {
    return await _budgetData.addBudget(data);
  }
}
