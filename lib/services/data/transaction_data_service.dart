import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'dart:convert';

/// Data service for Transaction CRUD operations.
/// Extracted from the monolithic LocalDataService facade.
class TransactionDataService {
  final LocalDatabaseService _dbService;
  final LocalAuthService _authService;
  final _uuid = const Uuid();

  TransactionDataService({
    LocalDatabaseService? dbService,
    LocalAuthService? authService,
  }) : _dbService = dbService ?? LocalDatabaseService(),
       _authService = authService ?? LocalAuthService();

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    return await _authService.getCurrentUserId();
  }

  /// Get transactions with filters
  Future<Map<String, dynamic>> getTransactions({
    int limit = 100,
    int offset = 0,
    String? type,
    String? categoryId,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      var where = 't.user_id_232143 = ?';
      var whereArgs = <dynamic>[userId];

      if (type != null) {
        where += ' AND t.type_232143 = ?';
        whereArgs.add(type);
      }
      if (categoryId != null) {
        where += ' AND t.category_id_232143 = ?';
        whereArgs.add(categoryId);
      }
      if (startDate != null) {
        where += ' AND t.transaction_date_232143 >= ?';
        whereArgs.add(startDate);
      }
      if (endDate != null) {
        where += ' AND t.transaction_date_232143 <= ?';
        whereArgs.add(endDate);
      }
      if (search != null && search.isNotEmpty) {
        where += ' AND t.description_232143 LIKE ?';
        whereArgs.add('%$search%');
      }

      // Get total count
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM transactions_232143 t WHERE $where',
        whereArgs,
      );
      final total = countResult.first['count'] as int;

      // Get transactions
      final transactions = await db.rawQuery(
        '''
        SELECT
        t.*,
        c.name_232143 AS category_name,
        c.color_232143 AS category_color,
        c.icon_232143 AS category_icon,
        a.name_232143 AS account_name,
        a.type_232143 AS account_type,
        a.color_232143 AS account_color
        FROM transactions_232143 t
        LEFT JOIN categories_232143 c ON t.category_id_232143 = c.category_id_232143
        LEFT JOIN accounts_232143 a ON t.account_id_232143 = a.account_id_232143
        WHERE $where
        ORDER BY t.transaction_date_232143 DESC, t.created_at_232143 DESC
        LIMIT ? OFFSET ?
        ''',
        [...whereArgs, limit, offset],
      );

      return {
        'transactions': transactions,
        'total': total,
        'count': transactions.length,
        'hasMore': offset + transactions.length < total,
        'limit': limit,
        'offset': offset,
      };
    } catch (e) {
      LoggerService.error('Error getting transactions', error: e);
      rethrow;
    }
  }

  /// Get single transaction
  Future<Map<String, dynamic>?> getTransaction(String id) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final transactions = await db.rawQuery(
        '''SELECT
          t.*,
          c.name_232143 AS category_name,
          c.color_232143 AS category_color,
          c.icon_232143 AS category_icon,
          a.name_232143 AS account_name,
          a.type_232143 AS account_type,
          a.color_232143 AS account_color
        FROM transactions_232143 t
        LEFT JOIN categories_232143 c ON t.category_id_232143 = c.category_id_232143
        LEFT JOIN accounts_232143 a ON t.account_id_232143 = a.account_id_232143
        WHERE t.transaction_id_232143 = ? AND t.user_id_232143 = ?''',
        [id, userId],
      );

      return transactions.isNotEmpty ? transactions.first : null;
    } catch (e) {
      LoggerService.error('Error getting transaction', error: e);
      rethrow;
    }
  }

  /// Add transaction
  Future<Map<String, dynamic>> addTransaction(
    Map<String, dynamic> transactionData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final transactionId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      // Prepare location data
      String? locationDataJson;
      if (transactionData['location_data'] != null) {
        locationDataJson = json.encode(transactionData['location_data']);
      }

      final data = {
        'transaction_id_232143': transactionId,
        'user_id_232143': userId,
        'account_id_232143': transactionData['account_id'],
        'amount_232143': transactionData['amount'],
        'type_232143': transactionData['type'],
        'category_id_232143': transactionData['category_id'],
        'description_232143': transactionData['description'] ?? '',
        'location_name_232143': transactionData['location_name'],
        'latitude_232143': transactionData['latitude'],
        'longitude_232143': transactionData['longitude'],
        'location_data_232143': locationDataJson,
        'payment_method_232143': transactionData['payment_method'] ?? 'cash',
        'receipt_image_url_232143': transactionData['receipt_image_url'],
        'is_recurring_232143': transactionData['is_recurring'] == true ? 1 : 0,
        'recurring_pattern_232143': transactionData['recurring_pattern'],
        'tags_232143': transactionData['tags'],
        'transaction_date_232143':
            transactionData['transaction_date'] ??
            DateTime.now().toIso8601String().split('T')[0],
        'transaction_time_232143': transactionData['transaction_time'],
        'created_at_232143': now,
        'updated_at_232143': now,
      };

      await db.insert('transactions_232143', data);

      // Sync account balance when transaction is linked to an account
      if (transactionData['account_id'] != null) {
        final accountId = transactionData['account_id'].toString();
        final amount = (transactionData['amount'] as num).toDouble();
        final type = transactionData['type'] as String;

        double balanceChange = 0;
        if (type == 'income') {
          balanceChange = amount;
        } else if (type == 'expense') {
          balanceChange = -amount;
        }

        if (balanceChange != 0) {
          await _adjustAccountBalance(db, accountId, balanceChange);
        }
      }

      LoggerService.info('✅ Transaction added: $transactionId');
      return {'transaction': data};
    } catch (e) {
      LoggerService.error('Error adding transaction', error: e);
      rethrow;
    }
  }

  /// Update transaction
  Future<Map<String, dynamic>> updateTransaction(
    String id,
    Map<String, dynamic> transactionData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final now = DateTime.now().toIso8601String();

      // Get old transaction to reverse its balance effect
      final oldTxn = await db.query(
        'transactions_232143',
        where: 'transaction_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [id, userId],
        limit: 1,
      );

      if (oldTxn.isNotEmpty) {
        final oldAccountId = oldTxn.first['account_id_232143'] as String?;
        final oldAmount =
            (oldTxn.first['amount_232143'] as num?)?.toDouble() ?? 0.0;
        final oldType = oldTxn.first['type_232143'] as String? ?? '';

        // Reverse old balance effect
        if (oldAccountId != null && oldAccountId.isNotEmpty) {
          double reverseChange = 0;
          if (oldType == 'income') {
            reverseChange = -oldAmount;
          } else if (oldType == 'expense') {
            reverseChange = oldAmount;
          }
          if (reverseChange != 0) {
            await _adjustAccountBalance(db, oldAccountId, reverseChange);
          }
        }
      }

      final updateData = <String, dynamic>{'updated_at_232143': now};

      if (transactionData.containsKey('amount')) {
        updateData['amount_232143'] = transactionData['amount'];
      }
      if (transactionData.containsKey('type')) {
        updateData['type_232143'] = transactionData['type'];
      }
      if (transactionData.containsKey('category_id')) {
        updateData['category_id_232143'] = transactionData['category_id'];
      }
      if (transactionData.containsKey('description')) {
        updateData['description_232143'] = transactionData['description'];
      }
      if (transactionData.containsKey('location_data')) {
        updateData['location_data_232143'] = json.encode(
          transactionData['location_data'],
        );
      }
      if (transactionData.containsKey('transaction_date')) {
        updateData['transaction_date_232143'] =
            transactionData['transaction_date'];
      }
      if (transactionData.containsKey('account_id')) {
        updateData['account_id_232143'] = transactionData['account_id'];
      }
      if (transactionData.containsKey('is_recurring')) {
        updateData['is_recurring_232143'] =
            transactionData['is_recurring'] == true ? 1 : 0;
      }

      await db.update(
        'transactions_232143',
        updateData,
        where: 'transaction_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [id, userId],
      );

      // Apply new balance effect after update
      final newAccountId = transactionData['account_id'] as String?;
      final newAmount = (transactionData['amount'] as num?)?.toDouble();
      final newType = transactionData['type'] as String?;
      if (newAccountId != null &&
          newAccountId.isNotEmpty &&
          newAmount != null &&
          newType != null) {
        double newChange = 0;
        if (newType == 'income') {
          newChange = newAmount;
        } else if (newType == 'expense') {
          newChange = -newAmount;
        }
        if (newChange != 0) {
          await _adjustAccountBalance(db, newAccountId, newChange);
        }
      }

      final updated = await getTransaction(id);
      return {'transaction': updated};
    } catch (e) {
      LoggerService.error('Error updating transaction', error: e);
      rethrow;
    }
  }

  /// Delete transaction
  Future<void> deleteTransaction(String id) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;

      // Get the transaction first to reverse its balance effect
      final oldTxn = await db.query(
        'transactions_232143',
        where: 'transaction_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [id, userId],
        limit: 1,
      );

      if (oldTxn.isNotEmpty) {
        final accountId = oldTxn.first['account_id_232143'] as String?;
        if (accountId != null && accountId.isNotEmpty) {
          final amount =
              (oldTxn.first['amount_232143'] as num?)?.toDouble() ?? 0.0;
          final type = oldTxn.first['type_232143'] as String? ?? '';
          double balanceChange = 0;
          if (type == 'income') {
            balanceChange = -amount;
          } else if (type == 'expense') {
            balanceChange = amount;
          }

          if (balanceChange != 0) {
            await _adjustAccountBalance(db, accountId, balanceChange);
          }
        }
      }

      await db.delete(
        'transactions_232143',
        where: 'transaction_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [id, userId],
      );

      LoggerService.info('✅ Transaction deleted: $id');
    } catch (e) {
      LoggerService.error('Error deleting transaction', error: e);
      rethrow;
    }
  }

  /// Adjust an account's balance by a delta amount
  Future<void> _adjustAccountBalance(
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
      LoggerService.info(
        '✅ Account balance adjusted: $accountId ${delta >= 0 ? '+' : ''}$delta (new: $newBalance)',
      );
    }
  }

  /// Get financial summary
  Future<Map<String, dynamic>> getFinancialSummary({
    int? year,
    int? month,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final now = DateTime.now();
      final targetYear = year ?? now.year;
      final targetMonth = month ?? now.month;

      // Build date filter
      final startDate =
          '$targetYear-${targetMonth.toString().padLeft(2, '0')}-01';
      final endDate =
          '$targetYear-${targetMonth.toString().padLeft(2, '0')}-31';

      final result = await db.rawQuery(
        '''
        SELECT 
          type_232143,
          SUM(amount_232143) as total_amount_232143,
          COUNT(*) as transaction_count
        FROM transactions_232143
        WHERE user_id_232143 = ?
          AND transaction_date_232143 >= ?
          AND transaction_date_232143 <= ?
        GROUP BY type_232143
      ''',
        [userId, startDate, endDate],
      );

      final summaryMap = <String, Map<String, dynamic>>{};
      for (var row in result) {
        final type = row['type_232143'] as String;
        summaryMap[type] = {
          'total_amount':
              (row['total_amount_232143'] as num?)?.toDouble() ?? 0.0,
          'transaction_count': row['transaction_count'] as int? ?? 0,
        };
      }

      return {'year': targetYear, 'month': targetMonth, 'summary': summaryMap};
    } catch (e) {
      LoggerService.error('Error getting financial summary', error: e);
      rethrow;
    }
  }
}
