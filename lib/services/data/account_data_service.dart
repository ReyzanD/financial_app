import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/logger_service.dart';

/// Data service for Account CRUD operations.
/// Extracted from the monolithic LocalDataService facade.
class AccountDataService {
  final LocalDatabaseService _dbService;
  final LocalAuthService _authService;
  final _uuid = const Uuid();

  AccountDataService({
    LocalDatabaseService? dbService,
    LocalAuthService? authService,
  }) : _dbService = dbService ?? LocalDatabaseService(),
       _authService = authService ?? LocalAuthService();

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    return await _authService.getCurrentUserId();
  }

  /// Get accounts
  Future<List<Map<String, dynamic>>> getAccounts({
    bool activeOnly = true,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      var where = 'user_id_232143 = ?';
      var whereArgs = <dynamic>[userId];

      if (activeOnly) {
        where += ' AND is_active_232143 = 1';
      }

      final accounts = await db.query(
        'accounts_232143',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'created_at_232143 ASC',
      );

      return List<Map<String, dynamic>>.from(accounts);
    } catch (e) {
      LoggerService.error('Error getting accounts', error: e);
      rethrow;
    }
  }

  /// Add account
  Future<Map<String, dynamic>> addAccount(
    Map<String, dynamic> accountData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final accountId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final data = {
        'account_id_232143': accountId,
        'user_id_232143': userId,
        'name_232143': accountData['name'],
        'type_232143': accountData['type'] ?? 'cash',
        'icon_232143': accountData['icon'] ?? 'wallet',
        'color_232143': accountData['color'] ?? '#8B5FBF',
        'balance_232143': accountData['balance'] ?? 0.0,
        'currency_232143': accountData['currency'] ?? 'IDR',
        'account_number_232143': accountData['account_number'],
        'bank_name_232143': accountData['bank_name'],
        'is_active_232143': accountData['is_active'] != false ? 1 : 0,
        'is_default_232143': accountData['is_default'] == true ? 1 : 0,
        'created_at_232143': now,
        'updated_at_232143': now,
      };

      await db.insert('accounts_232143', data);
      LoggerService.info('✅ Account added: $accountId');
      return {'account': data};
    } catch (e) {
      LoggerService.error('Error adding account', error: e);
      rethrow;
    }
  }

  /// Update account
  Future<Map<String, dynamic>> updateAccount(
    String accountId,
    Map<String, dynamic> accountData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final now = DateTime.now().toIso8601String();

      final updateData = <String, dynamic>{'updated_at_232143': now};

      if (accountData.containsKey('name')) {
        updateData['name_232143'] = accountData['name'];
      }
      if (accountData.containsKey('type')) {
        updateData['type_232143'] = accountData['type'];
      }
      if (accountData.containsKey('icon')) {
        updateData['icon_232143'] = accountData['icon'];
      }
      if (accountData.containsKey('color')) {
        updateData['color_232143'] = accountData['color'];
      }
      if (accountData.containsKey('balance')) {
        updateData['balance_232143'] = accountData['balance'];
      }
      if (accountData.containsKey('currency')) {
        updateData['currency_232143'] = accountData['currency'];
      }
      if (accountData.containsKey('account_number')) {
        updateData['account_number_232143'] = accountData['account_number'];
      }
      if (accountData.containsKey('bank_name')) {
        updateData['bank_name_232143'] = accountData['bank_name'];
      }
      if (accountData.containsKey('is_active')) {
        updateData['is_active_232143'] = accountData['is_active'] ? 1 : 0;
      }
      if (accountData.containsKey('is_default')) {
        updateData['is_default_232143'] = accountData['is_default'] ? 1 : 0;
      }

      await db.update(
        'accounts_232143',
        updateData,
        where: 'account_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [accountId, userId],
      );

      LoggerService.info('✅ Account updated: $accountId');
      final updated = await db.query(
        'accounts_232143',
        where: 'account_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [accountId, userId],
        limit: 1,
      );
      return {'account': updated.isNotEmpty ? updated.first : {}};
    } catch (e) {
      LoggerService.error('Error updating account', error: e);
      rethrow;
    }
  }

  /// Delete account
  Future<Map<String, dynamic>> deleteAccount(String accountId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final rowsDeleted = await db.delete(
        'accounts_232143',
        where: 'account_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [accountId, userId],
      );

      if (rowsDeleted > 0) {
        LoggerService.info('✅ Account deleted: $accountId');
        return {'success': true, 'message': 'Account deleted successfully'};
      } else {
        return {'success': false, 'message': 'Account not found'};
      }
    } catch (e) {
      LoggerService.error('Error deleting account', error: e);
      rethrow;
    }
  }

  /// Get single account
  Future<Map<String, dynamic>> getAccount(String accountId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final accounts = await db.query(
        'accounts_232143',
        where: 'account_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [accountId, userId],
        limit: 1,
      );

      return {'account': accounts.isNotEmpty ? accounts.first : null};
    } catch (e) {
      LoggerService.error('Error getting account', error: e);
      rethrow;
    }
  }

  /// Get account summary
  Future<Map<String, dynamic>> getAccountSummary() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final result = await db.rawQuery(
        '''
        SELECT type_232143, SUM(balance_232143) as total_balance, COUNT(*) as count
        FROM accounts_232143
        WHERE user_id_232143 = ? AND is_active_232143 = 1
        GROUP BY type_232143
        ''',
        [userId],
      );

      double totalBalance = 0;
      final byType = <String, dynamic>{};

      for (var row in result) {
        final type = row['type_232143'] as String;
        final balance = (row['total_balance'] as num?)?.toDouble() ?? 0.0;
        totalBalance += balance;
        byType[type] = {'balance': balance, 'count': row['count']};
      }

      return {
        'total_balance': totalBalance,
        'by_type': byType,
        'account_count': result.length,
      };
    } catch (e) {
      LoggerService.error('Error getting account summary', error: e);
      rethrow;
    }
  }

  /// Adjust an account's balance by a delta amount.
  /// Used by other data services (transactions, goals, obligations).
  Future<void> adjustAccountBalance(
    Database db,
    String accountId,
    double delta,
  ) async {
    final accountResult = await db.query(
      'accounts_232143',
      where: 'account_id_232143 = ?',
      whereArgs: [accountId],
      limit: 1,
    );

    if (accountResult.isNotEmpty) {
      final currentBalance =
          (accountResult.first['balance_232143'] as num?)?.toDouble() ?? 0.0;
      final newBalance = currentBalance + delta;
      await db.update(
        'accounts_232143',
        {
          'balance_232143': newBalance,
          'updated_at_232143': DateTime.now().toIso8601String(),
        },
        where: 'account_id_232143 = ?',
        whereArgs: [accountId],
      );
    }
  }
}
