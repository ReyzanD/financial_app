import 'base_api.dart';

/// API client for goal-related endpoints
class GoalApi {
  /// Get all goals
  static Future<List<dynamic>> getGoals() async {
    final response = await BaseApiClient.get('goals');
    return response['goals'] ?? [];
  }

  /// Get single goal by ID
  static Future<Map<String, dynamic>> getGoal(String id) async {
    final response = await BaseApiClient.get('goals/$id');
    return response['goal'] ?? {};
  }

  /// Create new goal
  static Future<Map<String, dynamic>> createGoal(
    Map<String, dynamic> goalData,
  ) async {
    return await BaseApiClient.post('goals', goalData);
  }

  /// Update goal
  static Future<Map<String, dynamic>> updateGoal(
    String id,
    Map<String, dynamic> goalData,
  ) async {
    return await BaseApiClient.put('goals/$id', goalData);
  }

  /// Delete goal
  static Future<Map<String, dynamic>> deleteGoal(String id) async {
    return await BaseApiClient.delete('goals/$id');
  }

  /// Add contribution to goal
  static Future<Map<String, dynamic>> addContribution(
    String id,
    Map<String, dynamic> contributionData,
  ) async {
    return await BaseApiClient.post('goals/$id/contribute', contributionData);
  }
}
