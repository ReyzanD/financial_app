import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:financial_app/services/pin_auth_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/encryption_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/widgets/onboarding/onboarding_flow_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Authentication Service - Now uses local database (no backend server required)
class AuthService {
  final LocalAuthService _localAuth = LocalAuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final PinAuthService _pinAuthService = PinAuthService();

  /// Login user (local database)
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      // Data isolation is handled by user_id_232143 filtering in all data services
      final result = await _localAuth.login(email, password);

      // #full-stack-sync: token is now a session UUID, not the raw user_id
      await _storage.write(key: 'auth_token', value: result['access_token']);

      return result;
    } catch (e) {
      LoggerService.error('Login error', error: e);
      throw Exception('Login error: $e');
    }
  }

  /// Register new user (local database)
  Future<Map<String, dynamic>?> register(String email, String password, String fullName) async {
    try {
      final result = await _localAuth.register(email: email, password: password, fullName: fullName);

      // Auto-login: store auth token (redundant with local_auth but defensive)
      final sessionToken = result['access_token'] as String;
      final userId = result['user_id'] as String;
      final prefs = await SharedPreferences.getInstance();

      await _storage.write(key: 'auth_token', value: sessionToken);
      await prefs.setString('current_user_id', userId);

      LoggerService.info('Registration successful');
      return {'access_token': sessionToken, 'message': 'User registered successfully', 'user': result};
    } catch (e) {
      LoggerService.error('Error during registration', error: e);
      throw Exception('Registration error: $e');
    }
  }

  Future<void> logout() async {
    // Clear PIN first
    await _pinAuthService.clearPin();

    // Data isolation is handled by user_id_232143 filtering in all data services
    // Logout from local auth
    await _localAuth.logout();

    // Clear auth token only — do NOT call deleteAll() which would wipe
    // AES-256 encryption keys stored by EncryptionService, making all
    // encrypted data permanently unrecoverable.
    await _storage.delete(key: 'auth_token');

    // Clear user-specific SharedPreferences data
    final prefs = await SharedPreferences.getInstance();
    await OnboardingFlowManager.resetOnboarding();
    await prefs.remove('default_tab_index');
    // Keep app-level settings like theme, notifications preferences
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  /// Validates if token looks like a well-formed UUID (length 36)
  bool isValidTokenFormat(String? token) {
    if (token == null || token.isEmpty) return false;
    // Session tokens and user IDs are both UUIDs (36 chars with hyphens)
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
      await db.delete('users_232143', where: 'user_id_232143 = ?', whereArgs: [userId]);

      // Explicitly clear encryption keys since the account is being deleted
      getIt<EncryptionService>().clearKey();

      await logout();
      LoggerService.info('Account deleted successfully');
    } catch (e) {
      LoggerService.error('Delete account error', error: e);
      throw Exception('Delete account error: $e');
    }
  }
}
