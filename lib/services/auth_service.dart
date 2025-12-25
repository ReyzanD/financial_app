import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:financial_app/core/app_config.dart';
import 'package:financial_app/services/pin_auth_service.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String get baseUrl => AppConfig.effectiveAuthBaseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final PinAuthService _pinAuthService = PinAuthService();

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      // Clear any cached data from previous sessions before login
      ApiService.clearCache();

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        // Ensure response body is properly decoded with UTF-8 encoding
        final responseBody = utf8.decode(response.bodyBytes);
        final data = json.decode(responseBody);
        await _storage.write(key: 'auth_token', value: data['access_token']);
        return data;
      } else {
        // Ensure error response is properly decoded with UTF-8 encoding
        final responseBody = utf8.decode(response.bodyBytes);
        final error = json.decode(responseBody);
        throw Exception(error['error'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  Future<Map<String, dynamic>?> register(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final url = '$baseUrl/register';
      LoggerService.info('Registering user at: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode({
          'email': email,
          'password': password,
          'full_name': fullName,
        }),
      );

      LoggerService.info('Registration response status: ${response.statusCode}');
      LoggerService.info('Registration response body: ${response.body}');

      if (response.statusCode == 201) {
        // Ensure response body is properly decoded with UTF-8 encoding
        final responseBody = utf8.decode(response.bodyBytes);
        final data = json.decode(responseBody);
        return data;
      } else {
        // Ensure error response is properly decoded with UTF-8 encoding
        final responseBody = utf8.decode(response.bodyBytes);
        
        // Try to parse as JSON, if fails, return the raw response
        try {
          final error = json.decode(responseBody);
          throw Exception(error['error'] ?? 'Registration failed');
        } catch (e) {
          // If response is not JSON (e.g., HTML 404 page), throw with status code
          throw Exception('Registration failed (${response.statusCode}): $responseBody');
        }
      }
    } catch (e) {
      LoggerService.error('Error during registration', error: e);
      throw Exception('Registration error: $e');
    }
  }

  Future<void> logout() async {
    // Clear PIN first
    await _pinAuthService.clearPin();

    // Clear all API caches (critical to prevent data leakage between users)
    ApiService.clearCache();

    // Clear auth token and secure storage
    await _storage.delete(key: 'auth_token');
    await _storage.deleteAll();

    // Clear user-specific SharedPreferences data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_completed');
    await prefs.remove('default_tab_index');
    // Keep app-level settings like theme, notifications preferences
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  /// Validates if the JWT token has correct format (3 segments)
  bool isValidTokenFormat(String? token) {
    if (token == null || token.isEmpty) return false;
    final segments = token.split('.');
    return segments.length == 3;
  }

  /// Checks if user has a valid token stored
  Future<bool> hasValidToken() async {
    final token = await getToken();
    return isValidTokenFormat(token);
  }

  Future<void> deleteAccount() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/account'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await logout();
      } else {
        // Ensure error response is properly decoded with UTF-8 encoding
        final responseBody = utf8.decode(response.bodyBytes);
        final error = json.decode(responseBody);
        throw Exception(error['error'] ?? 'Failed to delete account');
      }
    } catch (e) {
      throw Exception('Delete account error: $e');
    }
  }
}
