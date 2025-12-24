import 'base_api.dart';

/// API client for transaction-related endpoints
class TransactionApi {
  /// Get transactions with optional filters and pagination
  static Future<Map<String, dynamic>> getTransactions({
    int limit = 10,
    int offset = 0,
    String? type,
    String? categoryId,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    String endpoint = 'transactions_232143?limit=$limit&offset=$offset';
    if (type != null) endpoint += '&type=$type';
    if (categoryId != null) endpoint += '&category_id=$categoryId';
    if (startDate != null) endpoint += '&start_date=$startDate';
    if (endDate != null) endpoint += '&end_date=$endDate';
    if (search != null && search.isNotEmpty) endpoint += '&search=$search';

    final response = await BaseApiClient.get(endpoint);
    return {
      'transactions': response['transactions'] ?? [],
      'total': response['total'] ?? 0,
      'count': response['count'] ?? 0,
      'has_more': response['has_more'] ?? false,
      'limit': response['limit'] ?? limit,
      'offset': response['offset'] ?? offset,
    };
  }

  /// Get single transaction by ID
  static Future<Map<String, dynamic>> getTransaction(String id) async {
    final response = await BaseApiClient.get('transactions_232143/$id');
    return response['transaction'] ?? {};
  }

  /// Add new transaction
  static Future<Map<String, dynamic>> addTransaction(
    Map<String, dynamic> transactionData,
  ) async {
    return await BaseApiClient.post('transactions_232143', transactionData);
  }

  /// Update transaction
  static Future<Map<String, dynamic>> updateTransaction(
    String id,
    Map<String, dynamic> transactionData,
  ) async {
    return await BaseApiClient.put('transactions_232143/$id', transactionData);
  }

  /// Delete transaction
  static Future<Map<String, dynamic>> deleteTransaction(String id) async {
    return await BaseApiClient.delete('transactions_232143/$id');
  }

  /// Get financial summary
  static Future<Map<String, dynamic>> getFinancialSummary({
    int? year,
    int? month,
  }) async {
    String endpoint = 'transactions_232143/analytics/summary';
    if (year != null && month != null) {
      endpoint += '?year=$year&month=$month';
    }
    return await BaseApiClient.get(endpoint);
  }

  /// Get transaction analytics
  static Future<Map<String, dynamic>> getAnalytics({
    required int year,
    required int month,
  }) async {
    final endpoint = 'transactions_232143/analytics?year=$year&month=$month';
    return await BaseApiClient.get(endpoint);
  }

  /// Get spending by category
  static Future<List<dynamic>> getSpendingByCategory({
    int? year,
    int? month,
  }) async {
    String endpoint = 'transactions_232143/analytics/by-category';
    if (year != null && month != null) {
      endpoint += '?year=$year&month=$month';
    }
    final response = await BaseApiClient.get(endpoint);
    return response['categories'] ?? [];
  }

  /// Get AI recommendations
  static Future<Map<String, dynamic>> getRecommendations() async {
    return await BaseApiClient.get('transactions_232143/recommendations');
  }
}
