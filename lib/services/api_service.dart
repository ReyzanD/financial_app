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

  // Generic GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: await _getHeaders(),
      );

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
        throw Exception('Bad request');
      case 401:
        throw Exception('Unauthorized');
      case 403:
        throw Exception('Forbidden');
      case 404:
        throw Exception('Not found');
      case 500:
        throw Exception('Server error');
      default:
        throw Exception('Unknown error: ${response.statusCode}');
    }
  }

  // User Profile
  Future<Map<String, dynamic>> getUserProfile() async {
    return await get('auth/profile');
  }

  // Transactions
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

  // Financial Summary
  Future<Map<String, dynamic>> getFinancialSummary() async {
    // Check if we have a valid cached response
    if (_cachedSummary != null && _lastSummaryFetch != null) {
      final age = DateTime.now().difference(_lastSummaryFetch!);
      if (age < _summaryTtl) {
        return _cachedSummary!;
      }
    }

    try {
      final response = await get('transactions_232143/analytics/summary');

      // Convert the list of summaries into a map by type
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

      // Update cache
      _cachedSummary = result;
      _lastSummaryFetch = DateTime.now();

      return result;
    } catch (e) {
      // If we have cached data and there's an error, return cached data
      if (_cachedSummary != null) {
        return _cachedSummary!;
      }
      rethrow;
    }
  }

  // Budgets
  Future<List<dynamic>> getBudgets() async {
    return await get('categories_232143/budgets');
  }

  // AI Recommendations
  Future<Map<String, dynamic>> getAIRecommendations() async {
    return await get('transactions_232143/recommendations');
  }

  // Categories
  Future<List<dynamic>> getCategories() async {
    final response = await get('categories_232143');
    return response['categories'] ?? [];
  }

  // Add Transaction
  Future<Map<String, dynamic>> addTransaction(
    Map<String, dynamic> transactionData,
  ) async {
    return await post('transactions_232143', transactionData);
  }
}
