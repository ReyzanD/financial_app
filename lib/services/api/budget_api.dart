import 'base_api.dart';

/// API client for budget-related endpoints
class BudgetApi {
  /// Get all budgets
  static Future<List<dynamic>> getBudgets() async {
    final response = await BaseApiClient.get('budgets');
    return response['budgets'] ?? [];
  }

  /// Get single budget by ID
  static Future<Map<String, dynamic>> getBudget(String id) async {
    final response = await BaseApiClient.get('budgets/$id');
    return response['budget'] ?? {};
  }

  /// Create new budget
  static Future<Map<String, dynamic>> createBudget(
    Map<String, dynamic> budgetData,
  ) async {
    return await BaseApiClient.post('budgets', budgetData);
  }

  /// Update budget
  static Future<Map<String, dynamic>> updateBudget(
    String id,
    Map<String, dynamic> budgetData,
  ) async {
    return await BaseApiClient.put('budgets/$id', budgetData);
  }

  /// Delete budget
  static Future<Map<String, dynamic>> deleteBudget(String id) async {
    return await BaseApiClient.delete('budgets/$id');
  }

  /// Get budget analytics
  static Future<Map<String, dynamic>> getBudgetAnalytics() async {
    return await BaseApiClient.get('budgets/analytics');
  }
}
