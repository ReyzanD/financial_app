/// API Service - Main facade for all API operations
///
/// This service provides a unified interface for all backend API calls.
/// It delegates to specific API clients (TransactionApi, BudgetApi, etc.)
/// and handles caching, error handling, and authentication.
///
/// Features:
/// - Automatic token management
/// - Response caching (2-minute TTL)
/// - Error handling and logging
/// - Request/response transformation
///
/// Usage:
/// ```dart
/// final apiService = ApiService();
/// final transactions = await apiService.getTransactions(limit: 50);
/// ```
///
/// Author: Financial App Team
/// Last Updated: 2024

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/api/transaction_api.dart';
import 'package:financial_app/services/api/budget_api.dart';
import 'package:financial_app/services/api/category_api.dart';
import 'package:financial_app/services/api/goal_api.dart';
import 'package:financial_app/services/api/obligation_api.dart';
import 'package:financial_app/services/api/base_api.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000/api/v1';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Cache layer for frequently accessed data
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 2);

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Public methods for use by other services
  Future<Map<String, String>> getHeaders() async {
    return await _getHeaders();
  }

  dynamic handleResponse(http.Response response) {
    return _handleResponse(response);
  }

  // Check if cached data is still valid
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  // Get cached data or null
  dynamic _getCached(String key) {
    if (_isCacheValid(key)) {
      LoggerService.cache('HIT', key);
      return _cache[key];
    }
    return null;
  }

  // Store data in cache
  void _setCache(String key, dynamic data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  // Clear specific cache or all
  static void clearCache([String? key]) {
    if (key != null) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    } else {
      _cache.clear();
      _cacheTimestamps.clear();

      // Clear all static caches (critical for logout to prevent data leakage)
      _cachedCategories = null;
      _categoriesCacheTime = null;
    }
  }

  // Clear instance-level caches (for when this service is reused)
  void clearInstanceCache() {
    _cachedSummary = null;
    _lastSummaryFetch = null;
    _cachedSummaryYear = null;
    _cachedSummaryMonth = null;
  }

  // Generic GET request with caching
  Future<dynamic> get(String endpoint, {bool useCache = true}) async {
    // Check cache first for GET requests
    if (useCache) {
      final cached = _getCached(endpoint);
      if (cached != null) return cached;
    }

    LoggerService.apiRequest('GET', endpoint);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: await _getHeaders(),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      LoggerService.apiResponse(response.statusCode, endpoint);
      final data = _handleResponse(response);

      // Cache the response
      if (useCache) {
        _setCache(endpoint, data);
      }

      return data;
    } catch (e) {
      LoggerService.error('GET request failed', error: e);
      rethrow;
    }
  }

  // Generic POST request
  Future<dynamic> post(String endpoint, dynamic data) async {
    LoggerService.apiRequest('POST', endpoint);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: await _getHeaders(),
        body: json.encode(data),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      // Clear cache on mutations
      clearCache();

      LoggerService.apiResponse(response.statusCode, endpoint);
      return _handleResponse(response);
    } catch (e) {
      LoggerService.error('POST request failed', error: e);
      rethrow;
    }
  }

  // Generic PUT request
  Future<dynamic> put(String endpoint, dynamic data) async {
    LoggerService.apiRequest('PUT', endpoint);
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: await _getHeaders(),
        body: json.encode(data),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      // Clear cache on mutations
      clearCache();

      LoggerService.apiResponse(response.statusCode, endpoint);
      return _handleResponse(response);
    } catch (e) {
      LoggerService.error('PUT request failed', error: e);
      rethrow;
    }
  }

  // Generic DELETE request
  Future<dynamic> delete(String endpoint) async {
    LoggerService.apiRequest('DELETE', endpoint);
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$endpoint'),
        headers: await _getHeaders(),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      // Clear cache on mutations
      clearCache();

      LoggerService.apiResponse(response.statusCode, endpoint);
      return _handleResponse(response);
    } catch (e) {
      LoggerService.error('DELETE request failed', error: e);
      rethrow;
    }
  }

  dynamic _handleResponse(http.Response response) {
    // Ensure response body is properly decoded with UTF-8 encoding
    final responseBody = utf8.decode(response.bodyBytes);

    switch (response.statusCode) {
      case 200:
        return json.decode(responseBody);
      case 201:
        return json.decode(responseBody);
      case 400:
        final errorBody = json.decode(responseBody);
        throw Exception('Bad request: ${errorBody['error'] ?? 'Invalid data'}');
      case 401:
        throw Exception('Unauthorized - Please login again');
      case 403:
        throw Exception('Forbidden - Access denied');
      case 404:
        throw Exception('Not found - Resource does not exist');
      case 422:
        // Unprocessable Entity - Validation failed
        try {
          final errorBody = json.decode(responseBody);
          final errorMsg =
              errorBody['error'] ?? errorBody['message'] ?? 'Validation failed';
          throw Exception('Validation error: $errorMsg');
        } catch (e) {
          throw Exception('Validation error: ${responseBody}');
        }
      case 500:
        LoggerService.error('Server error', error: responseBody);
        throw Exception('Server error - Please try again later');
      default:
        LoggerService.error(
          'HTTP ${response.statusCode}',
          error: responseBody,
        );
        throw Exception('Error ${response.statusCode}: ${responseBody}');
    }
  }

  // User Profile
  Future<Map<String, dynamic>> getUserProfile() async {
    return await get('auth/profile');
  }

  // Update User Profile
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: await _getHeaders(),
        body: json.encode(profileData),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Transactions - Delegated to TransactionApi
  /// Get transactions with pagination support
  /// Returns a map with 'transactions' list and pagination metadata
  Future<Map<String, dynamic>> getTransactions({
    String? type,
    int limit = 10,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    double? minAmount,
    double? maxAmount,
    String? search,
  }) async {
    return await TransactionApi.getTransactions(
      limit: limit,
      offset: offset,
      type: type,
      categoryId: categoryId,
      startDate: startDate?.toIso8601String().split('T')[0],
      endDate: endDate?.toIso8601String().split('T')[0],
      search: search,
    );
  }


  // Cache for financial summary
  Map<String, dynamic>? _cachedSummary;
  DateTime? _lastSummaryFetch;
  int? _cachedSummaryYear;
  int? _cachedSummaryMonth;
  static const _summaryTtl = Duration(minutes: 5);

  // Financial Summary - Delegated to TransactionApi
  Future<Map<String, dynamic>> getFinancialSummary({
    int? year,
    int? month,
  }) async {
    final now = DateTime.now();
    final targetYear = year ?? now.year;
    final targetMonth = month ?? now.month;

    if (_cachedSummary != null &&
        _lastSummaryFetch != null &&
        _cachedSummaryYear == targetYear &&
        _cachedSummaryMonth == targetMonth) {
      final age = DateTime.now().difference(_lastSummaryFetch!);
      if (age < _summaryTtl) {
        return _cachedSummary!;
      }
    }

    try {
      final response = await TransactionApi.getFinancialSummary(
        year: targetYear,
        month: targetMonth,
      );
      final List<dynamic> summaryList = response['summary'] ?? [];
      LoggerService.debug('[ApiService] Summary list from API: $summaryList');
      Map<String, dynamic> summaryMap = {};
      for (var item in summaryList) {
        final type = item['type_232143']?.toString() ?? '';
        LoggerService.debug('[ApiService] Processing type: $type, amount: ${item['total_amount_232143']}');
        summaryMap[type] = {
          'total_amount': double.parse(
            item['total_amount_232143']?.toString() ?? '0',
          ),
          'transaction_count': int.parse(
            item['transaction_count']?.toString() ?? '0',
          ),
        };
      }
      LoggerService.debug('[ApiService] Final summary map: $summaryMap');

      final result = {
        'year': targetYear,
        'month': targetMonth,
        'summary': summaryMap,
      };

      _cachedSummary = result;
      _cachedSummaryYear = targetYear;
      _cachedSummaryMonth = targetMonth;
      _lastSummaryFetch = DateTime.now();

      return result;
    } catch (e) {
      if (_cachedSummary != null) {
        return _cachedSummary!;
      }
      rethrow;
    }
  }

  // Budgets - Delegated to BudgetApi
  Future<List<dynamic>> getBudgets({bool activeOnly = true}) async {
    return await BudgetApi.getBudgets();
  }

  Future<Map<String, dynamic>> getBudget(String budgetId) async {
    return await BudgetApi.getBudget(budgetId);
  }

  Future<Map<String, dynamic>> createBudget(
    Map<String, dynamic> budgetData,
  ) async {
    return await BudgetApi.createBudget(budgetData);
  }

  Future<Map<String, dynamic>> updateBudget(
    String budgetId,
    Map<String, dynamic> budgetData,
  ) async {
    return await BudgetApi.updateBudget(budgetId, budgetData);
  }

  Future<Map<String, dynamic>> deleteBudget(String budgetId) async {
    return await BudgetApi.deleteBudget(budgetId);
  }

  Future<Map<String, dynamic>> getBudgetsSummary() async {
    return await BudgetApi.getBudgetAnalytics();
  }

  // AI Recommendations
  Future<dynamic> getAIRecommendations() async {
    return await get('transactions_232143/recommendations');
  }

  // Cache for categories (5 minutes)
  static List<dynamic>? _cachedCategories;
  static DateTime? _categoriesCacheTime;
  static const _categoriesCacheDuration = Duration(minutes: 5);

  // Get Categories (with caching)
  Future<List<dynamic>> getCategories({bool forceRefresh = false}) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh &&
        _cachedCategories != null &&
        _categoriesCacheTime != null &&
        DateTime.now().difference(_categoriesCacheTime!) <
            _categoriesCacheDuration) {
      LoggerService.cache('HIT', 'categories_232143');
      LoggerService.debug('Using cached categories (${_cachedCategories!.length} items)');
      return _cachedCategories!;
    }

    try {
      LoggerService.debug('Fetching fresh categories from API...');
      final categories = await CategoryApi.getCategories();

      // Update cache
      _cachedCategories = categories;
      _categoriesCacheTime = DateTime.now();
      LoggerService.success('Categories cached: ${categories.length} items');

      return categories;
    } catch (e) {
      LoggerService.warning('Failed to fetch categories', error: e);
      // Return cached data if available, even if expired
      if (_cachedCategories != null) {
        LoggerService.debug('Returning stale cache as fallback');
        return _cachedCategories!;
      }
      rethrow;
    }
  }

  // Add Transaction - Delegated to TransactionApi with cache clearing
  Future<Map<String, dynamic>> addTransaction(
    Map<String, dynamic> transactionData,
  ) async {
    final result = await TransactionApi.addTransaction(transactionData);
    // Clear caches after adding transaction
    LoggerService.debug('Clearing transaction caches after add...');
    _clearTransactionCaches();
    BaseApiClient.clearCache(); // Also clear base API cache
    return result;
  }

  // Update Transaction - Delegated to TransactionApi with cache clearing
  Future<Map<String, dynamic>> updateTransaction(
    String transactionId,
    Map<String, dynamic> transactionData,
  ) async {
    try {
      LoggerService.debug('Updating transaction: $transactionId');
      final result = await TransactionApi.updateTransaction(transactionId, transactionData);
      // Clear caches after updating transaction
      LoggerService.debug('Clearing transaction caches after update...');
      _clearTransactionCaches();
      BaseApiClient.clearCache();
      return result;
    } catch (e) {
      LoggerService.error('Update error', error: e);
      rethrow;
    }
  }

  // Delete Transaction - Delegated to TransactionApi with cache clearing
  Future<Map<String, dynamic>> deleteTransaction(String transactionId) async {
    try {
      LoggerService.debug('Deleting transaction: $transactionId');
      final result = await TransactionApi.deleteTransaction(transactionId);
      // Clear all transaction-related caches after deletion
      LoggerService.debug('Clearing transaction caches...');
      _clearTransactionCaches();
      BaseApiClient.clearCache();
      return result;
    } catch (e) {
      LoggerService.error('Delete error', error: e);
      rethrow;
    }
  }

  // Clear all transaction-related caches
  void _clearTransactionCaches() {
    // Clear all caches that contain transaction data
    final keysToRemove =
        _cache.keys
            .where(
              (key) =>
                  key.contains('transactions_232143') ||
                  key.contains('summary') ||
                  key.contains('analytics'),
            )
            .toList();

    for (var key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      LoggerService.debug('Cleared cache: $key');
    }

    // Also clear the old summary cache variables
    _cachedSummary = null;
    _lastSummaryFetch = null;
  }

  // Goals - Delegated to GoalApi
  Future<List<dynamic>> getGoals({bool includeCompleted = false}) async {
    return await GoalApi.getGoals();
  }

  Future<Map<String, dynamic>> getGoal(String goalId) async {
    return await GoalApi.getGoal(goalId);
  }

  Future<Map<String, dynamic>> createGoal(Map<String, dynamic> goalData) async {
    return await GoalApi.createGoal(goalData);
  }

  Future<Map<String, dynamic>> updateGoal(
    String goalId,
    Map<String, dynamic> goalData,
  ) async {
    return await GoalApi.updateGoal(goalId, goalData);
  }

  Future<Map<String, dynamic>> deleteGoal(String goalId) async {
    return await GoalApi.deleteGoal(goalId);
  }

  /// Add money to a goal (contribution)
  Future<Map<String, dynamic>> addGoalContribution(
    String goalId,
    double amount,
  ) async {
    return await GoalApi.addContribution(goalId, {'amount': amount});
  }

  Future<Map<String, dynamic>> getGoalsSummary() async {
    // Note: GoalApi doesn't have getGoalsSummary, so we'll keep the original implementation
    return await get('goals/summary');
  }

  // Obligations - Delegated to ObligationApi
  Future<List<dynamic>> getObligations({String? type}) async {
    return await ObligationApi.getObligations(type: type);
  }

  Future<List<dynamic>> getUpcomingObligations({int days = 7}) async {
    return await ObligationApi.getUpcomingObligations(days: days);
  }

  Future<Map<String, dynamic>> createObligation(
    Map<String, dynamic> obligationData,
  ) async {
    return await ObligationApi.createObligation(obligationData);
  }

  Future<Map<String, dynamic>> updateObligation(
    String obligationId,
    Map<String, dynamic> obligationData,
  ) async {
    return await ObligationApi.updateObligation(obligationId, obligationData);
  }

  Future<Map<String, dynamic>> deleteObligation(String obligationId) async {
    return await ObligationApi.deleteObligation(obligationId);
  }

  Future<Map<String, dynamic>> recordObligationPayment(
    String obligationId,
    Map<String, dynamic> paymentData,
  ) async {
    return await ObligationApi.recordObligationPayment(obligationId, paymentData);
  }

  /// Calculate obligations summary from obligations list
  Future<Map<String, dynamic>> getObligationsSummary() async {
    return await ObligationApi.getObligationsSummary();
  }

  // Recurring Transactions
  Future<List<dynamic>> getRecurringTransactions({
    bool activeOnly = true,
  }) async {
    String endpoint = 'recurring-transactions';
    if (!activeOnly) {
      endpoint += '?active_only=false';
    }
    final response = await get(endpoint);
    return response['recurring_transactions'] ?? [];
  }

  Future<Map<String, dynamic>> getRecurringTransaction(String id) async {
    final response = await get('recurring-transactions/$id');
    return response['recurring_transaction'] ?? {};
  }

  Future<Map<String, dynamic>> createRecurringTransaction(
    Map<String, dynamic> data,
  ) async {
    return await post('recurring-transactions', data);
  }

  Future<Map<String, dynamic>> updateRecurringTransaction(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await put('recurring-transactions/$id', data);
  }

  Future<void> deleteRecurringTransaction(String id) async {
    await delete('recurring-transactions/$id');
  }

  Future<Map<String, dynamic>> pauseRecurringTransaction(String id) async {
    return await post('recurring-transactions/$id/pause', {});
  }

  Future<Map<String, dynamic>> resumeRecurringTransaction(String id) async {
    return await post('recurring-transactions/$id/resume', {});
  }

  Future<List<dynamic>> getUpcomingRecurringTransactions({int days = 7}) async {
    final response = await get('recurring-transactions/upcoming?days=$days');
    return response['upcoming'] ?? [];
  }
}
