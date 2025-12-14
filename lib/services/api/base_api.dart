import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:financial_app/services/auth_service.dart';
import 'package:financial_app/services/logger_service.dart';

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
    LoggerService.cache('CLEARED', 'all');
  }

  /// Get from cache if available and fresh
  static dynamic getFromCache(String key) {
    if (_cache.containsKey(key)) {
      final timestamp = _cacheTimestamps[key];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < cacheDuration) {
        LoggerService.cache('HIT', key);
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

    LoggerService.apiRequest('GET', endpoint);
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('Connection timeout');
      },
    );

    LoggerService.apiResponse(response.statusCode, endpoint);

    if (response.statusCode == 200) {
      // Ensure response body is properly decoded with UTF-8 encoding
      final responseBody = utf8.decode(response.bodyBytes);
      final data = json.decode(responseBody);
      if (useCache) {
        saveToCache(cacheKey, data);
      }
      return data;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    } else {
      // Ensure error response is properly decoded with UTF-8 encoding
      final responseBody = utf8.decode(response.bodyBytes);
      throw Exception('Server error - Please try again later: $responseBody');
    }
  }

  /// Make POST request
  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    LoggerService.apiRequest('POST', endpoint);
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: json.encode(data),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('Connection timeout');
      },
    );

    LoggerService.apiResponse(response.statusCode, endpoint);

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Ensure response body is properly decoded with UTF-8 encoding
      final responseBody = utf8.decode(response.bodyBytes);
      return json.decode(responseBody);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    } else {
      // Ensure error response is properly decoded with UTF-8 encoding
      final responseBody = utf8.decode(response.bodyBytes);
      final errorBody = json.decode(responseBody);
      throw Exception(errorBody['error'] ?? 'Server error: $responseBody');
    }
  }

  /// Make PUT request
  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    LoggerService.apiRequest('PUT', endpoint);
    final headers = await getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: json.encode(data),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('Connection timeout');
      },
    );

    LoggerService.apiResponse(response.statusCode, endpoint);

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
    LoggerService.apiRequest('DELETE', endpoint);
    final headers = await getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('Connection timeout');
      },
    );

    LoggerService.apiResponse(response.statusCode, endpoint);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    } else {
      throw Exception('Server error - Please try again later');
    }
  }
}
