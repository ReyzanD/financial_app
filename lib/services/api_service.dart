import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:financial_app/services/logger_service.dart';

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

  // Transactions - Delegated to TransactionApiService
  // Use: TransactionApiService().getTransactions()
  Future<List<dynamic>> getTransactions({
    String? type,
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    double? minAmount,
    double? maxAmount,
    String? search,
  }) async {
    String endpoint = 'transactions_232143';
    List<String> params = [];

    if (type != null) params.add('type=$type');
    if (startDate != null) {
      params.add('start_date=${_formatDate(startDate)}');
    }
    if (endDate != null) {
      params.add('end_date=${_formatDate(endDate)}');
    }
    if (categoryId != null) params.add('category_id=$categoryId');
    if (minAmount != null) params.add('min_amount=$minAmount');
    if (maxAmount != null) params.add('max_amount=$maxAmount');
    if (search != null && search.isNotEmpty) params.add('search=$search');
    if (limit > 0) params.add('limit=$limit');

    if (params.isNotEmpty) {
      endpoint += '?' + params.join('&');
    }

    final response = await get(endpoint);
    return response['transactions'] ?? [];
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // Cache for financial summary
  Map<String, dynamic>? _cachedSummary;
  DateTime? _lastSummaryFetch;
  int? _cachedSummaryYear;
  int? _cachedSummaryMonth;
  static const _summaryTtl = Duration(minutes: 5);

  // Financial Summary - Delegated to TransactionApiService
  // Use: TransactionApiService().getFinancialSummary()
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
      final response = await get(
        'transactions_232143/analytics/summary?year=$targetYear&month=$targetMonth',
      );
      final List<dynamic> summaryList = response['summary'] ?? [];
      print('📊 [ApiService] Summary list from API: $summaryList');
      Map<String, dynamic> summaryMap = {};
      for (var item in summaryList) {
        final type = item['type_232143']?.toString() ?? '';
        print('📊 [ApiService] Processing type: $type, amount: ${item['total_amount_232143']}');
        summaryMap[type] = {
          'total_amount': double.parse(
            item['total_amount_232143']?.toString() ?? '0',
          ),
          'transaction_count': int.parse(
            item['transaction_count']?.toString() ?? '0',
          ),
        };
      }
      print('📊 [ApiService] Final summary map: $summaryMap');

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

  // Budgets
  Future<List<dynamic>> getBudgets({bool activeOnly = true}) async {
    String endpoint = 'budgets';
    if (!activeOnly) {
      endpoint += '?active_only=false';
    }
    final response = await get(endpoint);
    return response['budgets'] ?? [];
  }

  Future<Map<String, dynamic>> getBudget(String budgetId) async {
    final response = await get('budgets/$budgetId');
    return response['budget'] ?? {};
  }

  Future<Map<String, dynamic>> createBudget(
    Map<String, dynamic> budgetData,
  ) async {
    return await post('budgets', budgetData);
  }

  Future<Map<String, dynamic>> updateBudget(
    String budgetId,
    Map<String, dynamic> budgetData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/budgets/$budgetId'),
        headers: await _getHeaders(),
        body: json.encode(budgetData),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> deleteBudget(String budgetId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/budgets/$budgetId'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getBudgetsSummary() async {
    return await get('budgets/summary');
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
      print('📦 Using cached categories (${_cachedCategories!.length} items)');
      return _cachedCategories!;
    }

    try {
      print('🔄 Fetching fresh categories from API...');
      final response = await get('categories_232143');
      final categories = response['categories'] ?? [];

      // Update cache
      _cachedCategories = categories;
      _categoriesCacheTime = DateTime.now();
      print('✅ Categories cached: ${categories.length} items');

      return categories;
    } catch (e) {
      print('⚠️ Failed to fetch categories: $e');
      // Return cached data if available, even if expired
      if (_cachedCategories != null) {
        print('📦 Returning stale cache as fallback');
        return _cachedCategories!;
      }
      rethrow;
    }
  }

  // Add Transaction
  Future<Map<String, dynamic>> addTransaction(
    Map<String, dynamic> transactionData,
  ) async {
    final result = await post('transactions_232143', transactionData);
    // Clear caches after adding transaction
    print('🧹 Clearing transaction caches after add...');
    _clearTransactionCaches();
    return result;
  }

  // Update Transaction
  Future<Map<String, dynamic>> updateTransaction(
    String transactionId,
    Map<String, dynamic> transactionData,
  ) async {
    try {
      print('✏️ Updating transaction: $transactionId');
      print('📝 Update data: $transactionData');
      final response = await http.put(
        Uri.parse('$baseUrl/transactions_232143/$transactionId'),
        headers: await _getHeaders(),
        body: json.encode(transactionData),
      );
      print('✅ Update response: ${response.statusCode}');
      final result = _handleResponse(response);

      // Clear caches after updating transaction
      print('🧹 Clearing transaction caches after update...');
      _clearTransactionCaches();

      return result;
    } catch (e) {
      print('❌ Update error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Delete Transaction
  Future<Map<String, dynamic>> deleteTransaction(String transactionId) async {
    try {
      print('🗑️ Deleting transaction: $transactionId');
      final response = await http.delete(
        Uri.parse('$baseUrl/transactions_232143/$transactionId'),
        headers: await _getHeaders(),
      );
      print('✅ Delete response: ${response.statusCode}');

      // Clear all transaction-related caches after deletion
      print('🧹 Clearing transaction caches...');
      _clearTransactionCaches();

      return _handleResponse(response);
    } catch (e) {
      print('❌ Delete error: $e');
      throw Exception('Network error: $e');
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
      print('   🗑️ Cleared cache: $key');
    }

    // Also clear the old summary cache variables
    _cachedSummary = null;
    _lastSummaryFetch = null;
  }

  // Goals
  Future<List<dynamic>> getGoals({bool includeCompleted = false}) async {
    String endpoint = 'goals';
    if (includeCompleted) {
      endpoint += '?include_completed=true';
    }
    final response = await get(endpoint);
    return response['goals'] ?? [];
  }

  Future<Map<String, dynamic>> getGoal(String goalId) async {
    final response = await get('goals/$goalId');
    return response['goal'] ?? {};
  }

  Future<Map<String, dynamic>> createGoal(Map<String, dynamic> goalData) async {
    return await post('goals', goalData);
  }

  Future<Map<String, dynamic>> updateGoal(
    String goalId,
    Map<String, dynamic> goalData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/goals/$goalId'),
        headers: await _getHeaders(),
        body: json.encode(goalData),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> deleteGoal(String goalId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/goals/$goalId'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Add money to a goal (contribution)
  Future<Map<String, dynamic>> addGoalContribution(
    String goalId,
    double amount,
  ) async {
    return await post('goals/$goalId/contribute', {'amount': amount});
  }

  Future<Map<String, dynamic>> getGoalsSummary() async {
    return await get('goals/summary');
  }

  // Obligations
  Future<List<dynamic>> getObligations({String? type}) async {
    String endpoint = 'obligations';
    if (type != null && type.isNotEmpty) {
      endpoint += '?type=$type';
    }
    final response = await get(endpoint);
    return response['obligations'] ?? [];
  }

  Future<List<dynamic>> getUpcomingObligations({int days = 7}) async {
    final response = await get('obligations/upcoming?days=$days');
    return response['obligations'] ?? [];
  }

  Future<Map<String, dynamic>> createObligation(
    Map<String, dynamic> obligationData,
  ) async {
    return await post('obligations', obligationData);
  }

  Future<Map<String, dynamic>> updateObligation(
    String obligationId,
    Map<String, dynamic> obligationData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/obligations/$obligationId'),
        headers: await _getHeaders(),
        body: json.encode(obligationData),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> deleteObligation(String obligationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/obligations/$obligationId'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> recordObligationPayment(
    String obligationId,
    Map<String, dynamic> paymentData,
  ) async {
    return await post('obligations/$obligationId/payments', paymentData);
  }

  /// Calculate obligations summary from obligations list
  Future<Map<String, dynamic>> getObligationsSummary() async {
    final obligations = await getObligations();

    double monthlyTotal = 0.0;
    double totalDebt = 0.0;

    for (var obligation in obligations) {
      // Handle both num and String types from database
      final monthlyAmountRaw = obligation['monthly_amount_232143'];
      final monthlyAmount =
          monthlyAmountRaw is num
              ? monthlyAmountRaw.toDouble()
              : (double.tryParse(monthlyAmountRaw?.toString() ?? '0') ?? 0.0);
      monthlyTotal += monthlyAmount;

      if (obligation['type_232143'] == 'debt') {
        final currentBalanceRaw = obligation['current_balance_232143'];
        final currentBalance =
            currentBalanceRaw is num
                ? currentBalanceRaw.toDouble()
                : (double.tryParse(currentBalanceRaw?.toString() ?? '0') ??
                    0.0);
        totalDebt += currentBalance;
      }
    }

    return {
      'monthlyTotal': monthlyTotal,
      'totalDebt': totalDebt,
      'obligationsCount': obligations.length,
    };
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
