import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:financial_app/services/pin_auth_service.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Authentication Service - Now uses local database (no backend server required)
class AuthService {
  final LocalAuthService _localAuth = LocalAuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final PinAuthService _pinAuthService = PinAuthService();

  /// Login user (local database)
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      // Clear any cached data from previous sessions before login
      ApiService.clearCache();

      final result = await _localAuth.login(email, password);
      
      // Store token (user_id) in secure storage
      await _storage.write(key: 'auth_token', value: result['access_token']);
      
      return result;
    } catch (e) {
      LoggerService.error('Login error', error: e);
      throw Exception('Login error: $e');
    }
  }

  /// Register new user (local database)
  Future<Map<String, dynamic>?> register(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      LoggerService.info('Registering user locally: $email');
      
      final result = await _localAuth.register(
        email: email,
        password: password,
        fullName: fullName,
      );

      LoggerService.info('Registration successful: $email');
      return {
        'message': 'User registered successfully',
        'user': result,
      };
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

    // Logout from local auth
    await _localAuth.logout();

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

  /// Validates if token exists (for local auth, token is user_id)
  bool isValidTokenFormat(String? token) {
    if (token == null || token.isEmpty) return false;
    // For local auth, token is UUID (36 chars)
    return token.length == 36;
  }

  /// Checks if user has a valid token stored
  Future<bool> hasValidToken() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;
    
    // Verify user still exists in database
    try {
      final user = await _localAuth.getCurrentUser();
      return user != null;
    } catch (e) {
      return false;
    }
  }

  /// Delete account (local database)
  Future<void> deleteAccount() async {
    try {
      final userId = await getToken();
      if (userId == null || userId.isEmpty) {
        throw Exception('Not authenticated');
      }

      // Delete user from local database (cascade will delete all related data)
      final db = await LocalDatabaseService().database;
      await db.delete(
        'users_232143',
        where: 'user_id_232143 = ?',
        whereArgs: [userId],
      );

      await logout();
      LoggerService.info('Account deleted successfully');
    } catch (e) {
      LoggerService.error('Delete account error', error: e);
      throw Exception('Delete account error: $e');
    }
  }
}
