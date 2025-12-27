import 'dart:convert';
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
      final existingUser = await db.query(
        'users_232143',
        where: 'email_232143 = ?',
        whereArgs: [email],
      );

      if (existingUser.isNotEmpty) {
        throw Exception('User already exists');
      }

      // Generate user ID
      final userId = _uuid.v4();

      // Hash password (simple SHA-256 for now, can be upgraded to bcrypt later)
      final passwordHash = _hashPassword(password);

      // Get current timestamp
      final now = DateTime.now().toIso8601String();

      // Insert user
      await db.insert(
        'users_232143',
        {
          'user_id_232143': userId,
          'email_232143': email,
          'password_hash_232143': passwordHash,
          'full_name_232143': fullName,
          'phone_number_232143': phoneNumber,
          'created_at_232143': now,
          'updated_at_232143': now,
        },
      );

      // Create default categories for the user
      await _createDefaultCategories(db, userId);

      LoggerService.info('✅ User registered: $email');

      return {
        'user_id': userId,
        'email': email,
        'full_name': fullName,
      };
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
      final users = await db.query(
        'users_232143',
        where: 'email_232143 = ?',
        whereArgs: [email],
      );

      if (users.isEmpty) {
        throw Exception('User not found');
      }

      final user = users.first;

      // Verify password
      final passwordHash = _hashPassword(password);
      if (user['password_hash_232143'] != passwordHash) {
        throw Exception('Invalid password');
      }

      // Update last login
      final now = DateTime.now().toIso8601String();
      await db.update(
        'users_232143',
        {'last_login_232143': now, 'updated_at_232143': now},
        where: 'user_id_232143 = ?',
        whereArgs: [user['user_id_232143']],
      );

      // Store user ID in secure storage (simulating JWT token)
      await _storage.write(
        key: 'auth_token',
        value: user['user_id_232143'] as String,
      );

      // Store user ID in SharedPreferences for quick access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', user['user_id_232143'] as String);

      LoggerService.info('✅ User logged in: $email');

      return {
        'access_token': user['user_id_232143'], // Using user_id as token
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

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      return token;
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
      final users = await db.query(
        'users_232143',
        where: 'user_id_232143 = ?',
        whereArgs: [userId],
      );

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

  /// Logout user
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    LoggerService.info('✅ User logged out');
  }

  /// Hash password (SHA-256 with salt)
  String _hashPassword(String password) {
    // Simple hash for now - can be upgraded to bcrypt if needed
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
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
      batch.insert(
        'categories_232143',
        {
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
        },
      );
    }

    await batch.commit(noResult: true);
    LoggerService.info('✅ Default categories created for user: $userId');
  }
}

