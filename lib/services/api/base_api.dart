import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:financial_app/services/auth_service.dart';

/// Base API client with common functionality
class BaseApiClient {
  static const String baseUrl = 'http://10.0.2.2:5000/api/v1';

  // Simple in-memory cache
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration cacheDuration = Duration(minutes: 5);

  /// Clear all cached data
  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    print('🗑️ API cache cleared');
  }

  /// Get from cache if available and fresh
  static dynamic getFromCache(String key) {
    if (_cache.containsKey(key)) {
      final timestamp = _cacheTimestamps[key];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < cacheDuration) {
        print('📦 Cache HIT: $key');
        return _cache[key];
      }
    }
    return null;
  }

  /// Save to cache
  static void saveToCache(String key, dynamic data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Get authorization headers
  static Future<Map<String, String>> getHeaders() async {
    final authService = AuthService();
    final token = await authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Make GET request
  static Future<dynamic> get(String endpoint, {bool useCache = true}) async {
    final cacheKey = endpoint;

    // Check cache first
    if (useCache) {
      final cached = getFromCache(cacheKey);
      if (cached != null) return cached;
    }

    print('🔼 GET: $baseUrl/$endpoint');
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );

    print('✅ Response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (useCache) {
        saveToCache(cacheKey, data);
      }
      return data;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    } else {
      throw Exception('Server error - Please try again later');
    }
  }

  /// Make POST request
  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    print('🔽 POST: $baseUrl/$endpoint');
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: json.encode(data),
    );

    print('✅ Response: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['error'] ?? 'Server error');
    }
  }

  /// Make PUT request
  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    print('🔄 PUT: $baseUrl/$endpoint');
    final headers = await getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: json.encode(data),
    );

    print('✅ Response: ${response.statusCode}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    } else {
      throw Exception('Server error - Please try again later');
    }
  }

  /// Make DELETE request
  static Future<dynamic> delete(String endpoint) async {
    print('🗑️ DELETE: $baseUrl/$endpoint');
    final headers = await getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );

    print('✅ Response: ${response.statusCode}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    } else {
      throw Exception('Server error - Please try again later');
    }
  }
}
