import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000/api/v1';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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

  // Generic GET request
  Future<dynamic> get(String endpoint) async {
    print('🔼 GET: $baseUrl/$endpoint');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: await _getHeaders(),
      );

      print('✅ Response: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Generic POST request
  Future<dynamic> post(String endpoint, dynamic data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: await _getHeaders(),
        body: json.encode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        return json.decode(response.body);
      case 201:
        return json.decode(response.body);
      case 400:
        final errorBody = json.decode(response.body);
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
          final errorBody = json.decode(response.body);
          final errorMsg =
              errorBody['error'] ?? errorBody['message'] ?? 'Validation failed';
          throw Exception('Validation error: $errorMsg');
        } catch (e) {
          throw Exception('Validation error: ${response.body}');
        }
      case 500:
        throw Exception('Server error - Please try again later');
      default:
        print('❌ HTTP ${response.statusCode}: ${response.body}');
        throw Exception('Error ${response.statusCode}: ${response.body}');
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
  Future<List<dynamic>> getTransactions({String? type, int limit = 10}) async {
    String endpoint = 'transactions_232143';
    List<String> params = [];

    if (type != null) params.add('type_232143=$type');
    if (limit > 0) params.add('limit=$limit');

    if (params.isNotEmpty) {
      endpoint += '?' + params.join('&');
    }

    final response = await get(endpoint);
    return response['transactions'] ?? [];
  }

  // Cache for financial summary
  Map<String, dynamic>? _cachedSummary;
  DateTime? _lastSummaryFetch;
  static const _summaryTtl = Duration(minutes: 5);

  // Financial Summary - Delegated to TransactionApiService
  // Use: TransactionApiService().getFinancialSummary()
  Future<Map<String, dynamic>> getFinancialSummary() async {
    if (_cachedSummary != null && _lastSummaryFetch != null) {
      final age = DateTime.now().difference(_lastSummaryFetch!);
      if (age < _summaryTtl) {
        return _cachedSummary!;
      }
    }

    try {
      final response = await get('transactions_232143/analytics/summary');
      final List<dynamic> summaryList = response['summary'] ?? [];
      Map<String, dynamic> summaryMap = {};
      for (var item in summaryList) {
        summaryMap[item['type_232143']] = {
          'total_amount': double.parse(
            item['total_amount_232143']?.toString() ?? '0',
          ),
          'transaction_count': int.parse(
            item['transaction_count']?.toString() ?? '0',
          ),
        };
      }

      final result = {
        'year': response['year'] ?? DateTime.now().year,
        'month': response['month'] ?? DateTime.now().month,
        'summary': summaryMap,
      };

      _cachedSummary = result;
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
  Future<Map<String, dynamic>> getAIRecommendations() async {
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
    return await post('transactions_232143', transactionData);
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
      return _handleResponse(response);
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
      return _handleResponse(response);
    } catch (e) {
      print('❌ Delete error: $e');
      throw Exception('Network error: $e');
    }
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
}
