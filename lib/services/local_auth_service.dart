import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local Authentication Service
/// Handles user registration and login without backend server
class LocalAuthService {
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final _uuid = const Uuid();

  /// PBKDF2 iterations (OWASP 2023 minimum recommendation: 600,000 for SHA-256)
  static const int _pbkdf2Iterations = 600000;
  static const int _saltLength = 32; // 256-bit salt

  // ====================================================================
  // PBKDF2-HMAC-SHA256 key derivation
  // ====================================================================

  /// Generate cryptographically random salt bytes
  Uint8List _generateSalt([int length = _saltLength]) {
    final random = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (_) => random.nextInt(256)));
  }

  /// PBKDF2-HMAC-SHA256 single-block derivation (output = 32 bytes).
  /// Uses the existing `crypto` package — no extra dependency needed.
  Uint8List _pbkdf2DeriveKey(String password, Uint8List salt, int iterations) {
    final passwordBytes = utf8.encode(password);
    final hmac = Hmac(sha256, passwordBytes);

    // INT_32_BE(1) — PBKDF2 block index, always 1 for single-block (32B) output
    final blockIndex = Uint8List(4)..[3] = 1;
    final input = Uint8List.fromList([...salt, ...blockIndex]);

    // U_1 = PRF(Password, Salt || INT_32_BE(1))
    var u = hmac.convert(input).bytes.toList();
    var t = List<int>.from(u);

    // U_2 … U_c with XOR accumulation (T = U_1 ⊕ U_2 ⊕ … ⊕ U_c)
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes.toList();
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }

    return Uint8List.fromList(t);
  }

  /// Hash password with a fresh random salt.
  /// Storage format: `base64(salt):base64(derived_key)`
  String _hashPassword(String password) {
    final salt = _generateSalt();
    final key = _pbkdf2DeriveKey(password, salt, _pbkdf2Iterations);
    return '${base64.encode(salt)}:${base64.encode(key)}';
  }

  /// Verify password against stored hash. Supports both:
  ///   - New PBKDF2 format:   `base64(salt):base64(key)`
  ///   - Legacy SHA-256 format: `hex_hash` (no colon)
  bool _verifyPassword(String password, String storedHash) {
    if (storedHash.contains(':')) {
      // PBKDF2 format
      final parts = storedHash.split(':');
      final salt = base64.decode(parts[0]);
      final expectedKey = base64.decode(parts[1]);
      final actualKey = _pbkdf2DeriveKey(password, Uint8List.fromList(salt), _pbkdf2Iterations);
      return _constantTimeEquals(actualKey.toList(), expectedKey);
    } else {
      // Legacy SHA-256 (no salt) — backward compatibility for existing users
      final bytes = utf8.encode(password);
      final hash = sha256.convert(bytes);
      return hash.toString() == storedHash;
    }
  }

  /// Constant-time comparison to prevent timing side-channel attacks
  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  // ====================================================================
  // Session token management
  // ====================================================================

  /// Generate a random session token (separate from user_id) and
  /// persist both the token and the user→token mapping.
  Future<String> _createSession(String userId) async {
    final sessionToken = _uuid.v4();
    await _storage.write(key: 'auth_token', value: sessionToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', userId);
    return sessionToken;
  }

  // ====================================================================
  // Public API
  // ====================================================================

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      final db = await _dbService.database;

      // Check if user already exists
      final existingUser = await db.query('users_232143', where: 'email_232143 = ?', whereArgs: [email]);

      if (existingUser.isNotEmpty) {
        throw Exception('User already exists');
      }

      // Generate user ID
      final userId = _uuid.v4();

      // Hash password with PBKDF2 + random salt
      final passwordHash = _hashPassword(password);

      // Get current timestamp
      final now = DateTime.now().toIso8601String();

      // Insert user
      await db.insert('users_232143', {
        'user_id_232143': userId,
        'email_232143': email,
        'password_hash_232143': passwordHash,
        'full_name_232143': fullName,
        'phone_number_232143': phoneNumber,
        'created_at_232143': now,
        'updated_at_232143': now,
      });

      // Create default categories for the user
      await _createDefaultCategories(db, userId);

      // Create default accounts for the user
      await _createDefaultAccounts(db, userId);

      // Generate and store session token (not user_id directly)
      final sessionToken = await _createSession(userId);

      LoggerService.info('User registered successfully');

      return {'user_id': userId, 'access_token': sessionToken, 'email': email, 'full_name': fullName};
    } catch (e) {
      LoggerService.error('Registration error', error: e);
      rethrow;
    }
  }

  /// Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final db = await _dbService.database;

      // Find user by email
      final users = await db.query('users_232143', where: 'email_232143 = ?', whereArgs: [email]);

      if (users.isEmpty) {
        throw Exception('User not found');
      }

      final user = users.first;

      // Verify password using PBKDF2 (supports legacy SHA-256 hashes too)
      final storedHash = user['password_hash_232143'] as String;
      if (!_verifyPassword(password, storedHash)) {
        throw Exception('Invalid password');
      }

      // Auto-upgrade legacy SHA-256 hash to PBKDF2 on successful login
      final now = DateTime.now().toIso8601String();
      if (!storedHash.contains(':')) {
        final newHash = _hashPassword(password);
        await db.update(
          'users_232143',
          {'password_hash_232143': newHash, 'updated_at_232143': now},
          where: 'user_id_232143 = ?',
          whereArgs: [user['user_id_232143']],
        );
      }

      // Update last login
      await db.update(
        'users_232143',
        {'last_login_232143': now, 'updated_at_232143': now},
        where: 'user_id_232143 = ?',
        whereArgs: [user['user_id_232143']],
      );

      // Generate session token (not user_id directly)
      final sessionToken = await _createSession(user['user_id_232143'] as String);

      LoggerService.info('User logged in successfully');

      return {
        'access_token': sessionToken,
        'user': {
          'user_id': user['user_id_232143'],
          'email': user['email_232143'],
          'full_name': user['full_name_232143'],
          'phone_number': user['phone_number_232143'],
          'income_range': user['income_range_232143'],
        },
      };
    } catch (e) {
      LoggerService.error('Login error', error: e);
      rethrow;
    }
  }

  /// Get current authenticated user ID from session mapping
  Future<String?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('current_user_id');
    } catch (e) {
      LoggerService.error('Error getting current user ID', error: e);
      return null;
    }
  }

  /// Get current user data
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return null;

      final db = await _dbService.database;
      final users = await db.query('users_232143', where: 'user_id_232143 = ?', whereArgs: [userId]);

      if (users.isEmpty) return null;

      final user = users.first;
      return {
        'user_id': user['user_id_232143'],
        'email': user['email_232143'],
        'full_name': user['full_name_232143'],
        'phone_number': user['phone_number_232143'],
        'income_range': user['income_range_232143'],
        'family_size': user['family_size_232143'],
        'base_location': user['base_location_232143'],
      };
    } catch (e) {
      LoggerService.error('Error getting current user', error: e);
      return null;
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final now = DateTime.now().toIso8601String();

      // Build update data map
      final updateData = <String, dynamic>{'updated_at_232143': now};

      // Add fields that can be updated
      if (profileData.containsKey('full_name')) {
        updateData['full_name_232143'] = profileData['full_name'];
      }
      if (profileData.containsKey('phone_number')) {
        updateData['phone_number_232143'] = profileData['phone_number'];
      }
      if (profileData.containsKey('date_of_birth')) {
        updateData['date_of_birth_232143'] = profileData['date_of_birth'];
      }
      if (profileData.containsKey('occupation')) {
        updateData['occupation_232143'] = profileData['occupation'];
      }
      if (profileData.containsKey('income_range')) {
        updateData['income_range_232143'] = profileData['income_range'];
      }
      if (profileData.containsKey('family_size')) {
        updateData['family_size_232143'] = profileData['family_size'];
      }
      if (profileData.containsKey('currency')) {
        updateData['currency_232143'] = profileData['currency'];
      }
      if (profileData.containsKey('base_location')) {
        updateData['base_location_232143'] = profileData['base_location'];
      }
      if (profileData.containsKey('financial_goals')) {
        updateData['financial_goals_232143'] = profileData['financial_goals'];
      }
      if (profileData.containsKey('risk_tolerance')) {
        updateData['risk_tolerance_232143'] = profileData['risk_tolerance'];
      }
      if (profileData.containsKey('notification_settings')) {
        updateData['notification_settings_232143'] = profileData['notification_settings'];
      }

      // Update user in database
      await db.update('users_232143', updateData, where: 'user_id_232143 = ?', whereArgs: [userId]);

      // Get updated user
      final users = await db.query('users_232143', where: 'user_id_232143 = ?', whereArgs: [userId]);

      if (users.isEmpty) {
        throw Exception('User not found after update');
      }

      final updatedUser = users.first;
      LoggerService.info('User profile updated: $userId');

      return {
        'user': {
          'user_id': updatedUser['user_id_232143'],
          'email': updatedUser['email_232143'],
          'full_name': updatedUser['full_name_232143'],
          'phone_number': updatedUser['phone_number_232143'],
          'date_of_birth': updatedUser['date_of_birth_232143'],
          'occupation': updatedUser['occupation_232143'],
          'income_range': updatedUser['income_range_232143'],
          'family_size': updatedUser['family_size_232143'],
          'currency': updatedUser['currency_232143'],
          'base_location': updatedUser['base_location_232143'],
          'financial_goals': updatedUser['financial_goals_232143'],
          'risk_tolerance': updatedUser['risk_tolerance_232143'],
          'notification_settings': updatedUser['notification_settings_232143'],
        },
      };
    } catch (e) {
      LoggerService.error('Profile update error', error: e);
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    LoggerService.info('User logged out');
  }

  /// Create default categories for new user
  Future<void> _createDefaultCategories(Database db, String userId) async {
    final defaultCategories = [
      // Income Categories
      {'name': 'Gaji', 'type': 'income', 'color': '#2ecc71', 'icon': 'work', 'order': 1},
      {'name': 'Investasi', 'type': 'income', 'color': '#27ae60', 'icon': 'trending_up', 'order': 2},
      {'name': 'Freelance', 'type': 'income', 'color': '#1abc9c', 'icon': 'computer', 'order': 3},

      // Expense Categories
      {'name': 'Makanan & Minuman', 'type': 'expense', 'color': '#e74c3c', 'icon': 'restaurant', 'order': 1},
      {'name': 'Transportasi', 'type': 'expense', 'color': '#f39c12', 'icon': 'directions_car', 'order': 2},
      {'name': 'Belanja', 'type': 'expense', 'color': '#9b59b6', 'icon': 'shopping_cart', 'order': 3},
      {'name': 'Hiburan', 'type': 'expense', 'color': '#34495e', 'icon': 'movie', 'order': 4},
      {'name': 'Kesehatan', 'type': 'expense', 'color': '#e67e22', 'icon': 'local_hospital', 'order': 5},
      {'name': 'Pendidikan', 'type': 'expense', 'color': '#2980b9', 'icon': 'school', 'order': 6},
      {'name': 'Tabungan', 'type': 'expense', 'color': '#16a085', 'icon': 'savings', 'order': 7},
      {'name': 'Tagihan & Utilitas', 'type': 'expense', 'color': '#95a5a6', 'icon': 'receipt', 'order': 8},
    ];

    final now = DateTime.now().toIso8601String();
    final batch = db.batch();

    for (final category in defaultCategories) {
      final categoryId = _uuid.v4();
      batch.insert('categories_232143', {
        'category_id_232143': categoryId,
        'user_id_232143': userId,
        'name_232143': category['name'],
        'type_232143': category['type'],
        'color_232143': category['color'],
        'icon_232143': category['icon'],
        'display_order_232143': category['order'],
        'is_system_default_232143': 1,
        'created_at_232143': now,
        'updated_at_232143': now,
      });
    }

    await batch.commit(noResult: true);
    LoggerService.info('Default categories created for user: $userId');
  }

  Future<void> _createDefaultAccounts(Database db, String userId) async {
    final defaultAccounts = [
      {'name': 'Cash', 'type': 'cash', 'icon': 'wallet', 'color': '#4CAF50', 'is_default': 1},
      {'name': 'Bank Account', 'type': 'bank', 'icon': 'account_balance', 'color': '#2196F3', 'is_default': 0},
      {'name': 'E-Wallet', 'type': 'e_wallet', 'icon': 'phone_android', 'color': '#FF9800', 'is_default': 0},
    ];

    final now = DateTime.now().toIso8601String();
    final batch = db.batch();

    for (final account in defaultAccounts) {
      final accountId = _uuid.v4();
      batch.insert('accounts_232143', {
        'account_id_232143': accountId,
        'user_id_232143': userId,
        'name_232143': account['name'],
        'type_232143': account['type'],
        'icon_232143': account['icon'],
        'color_232143': account['color'],
        'balance_232143': 0.0,
        'currency_232143': 'IDR',
        'is_active_232143': 1,
        'is_default_232143': account['is_default'],
        'created_at_232143': now,
        'updated_at_232143': now,
      });
    }

    await batch.commit(noResult: true);
    LoggerService.info('Default accounts created for user: $userId');
  }
}
