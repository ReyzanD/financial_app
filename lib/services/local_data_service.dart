import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'dart:convert';

/// Local Data Service - Replaces all API calls with local database operations
class LocalDataService {
  final LocalDatabaseService _dbService;
  final LocalAuthService _authService;
  final _uuid = const Uuid();

  LocalDataService({
    LocalDatabaseService? dbService,
    LocalAuthService? authService,
  }) : _dbService = dbService ?? LocalDatabaseService(),
       _authService = authService ?? LocalAuthService();

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    return await _authService.getCurrentUserId();
  }

  /// Expose auth service for profile updates
  LocalAuthService get authService => _authService;

  // ==================== TRANSACTIONS ====================

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

  // ==================== CATEGORIES ====================

  /// Get categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final categories = await db.query(
        'categories_232143',
        where: 'user_id_232143 = ?',
        whereArgs: [userId],
        orderBy: 'type_232143, display_order_232143',
      );

      return List<Map<String, dynamic>>.from(categories);
    } catch (e) {
      LoggerService.error('Error getting categories', error: e);
      rethrow;
    }
  }

  /// Add category
  Future<Map<String, dynamic>> addCategory(
    Map<String, dynamic> categoryData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final categoryId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final data = {
        'category_id_232143': categoryId,
        'user_id_232143': userId,
        'name_232143': categoryData['name'],
        'type_232143': categoryData['type'],
        'color_232143': categoryData['color'] ?? '#3498db',
        'icon_232143': categoryData['icon'] ?? 'receipt',
        'budget_limit_232143': categoryData['budget_limit'],
        'budget_period_232143': categoryData['budget_period'] ?? 'monthly',
        'display_order_232143': categoryData['display_order'] ?? 0,
        'created_at_232143': now,
        'updated_at_232143': now,
      };

      await db.insert('categories_232143', data);
      LoggerService.info('✅ Category added: $categoryId');
      return {'category': data};
    } catch (e) {
      LoggerService.error('Error adding category', error: e);
      rethrow;
    }
  }

  /// Update category
  Future<Map<String, dynamic>> updateCategory(
    String id,
    Map<String, dynamic> categoryData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final now = DateTime.now().toIso8601String();

      final updateData = <String, dynamic>{'updated_at_232143': now};

      if (categoryData.containsKey('name')) {
        updateData['name_232143'] = categoryData['name'];
      }
      if (categoryData.containsKey('color')) {
        updateData['color_232143'] = categoryData['color'];
      }
      if (categoryData.containsKey('icon')) {
        updateData['icon_232143'] = categoryData['icon'];
      }
      if (categoryData.containsKey('budget_limit')) {
        updateData['budget_limit_232143'] = categoryData['budget_limit'];
      }

      await db.update(
        'categories_232143',
        updateData,
        where: 'category_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [id, userId],
      );

      final categories = await db.query(
        'categories_232143',
        where: 'category_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [id, userId],
      );

      return {'category': categories.first};
    } catch (e) {
      LoggerService.error('Error updating category', error: e);
      rethrow;
    }
  }

  /// Delete category
  Future<void> deleteCategory(String id) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      await db.delete(
        'categories_232143',
        where: 'category_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [id, userId],
      );

      LoggerService.info('✅ Category deleted: $id');
    } catch (e) {
      LoggerService.error('Error deleting category', error: e);
      rethrow;
    }
  }

  // ==================== BUDGETS ====================

  /// Get budgets
  Future<List<Map<String, dynamic>>> getBudgets({
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

      final budgets = await db.query(
        'budgets_232143',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'period_start_232143 DESC',
      );

      return List<Map<String, dynamic>>.from(budgets);
    } catch (e) {
      LoggerService.error('Error getting budgets', error: e);
      rethrow;
    }
  }

  /// Add budget
  Future<Map<String, dynamic>> addBudget(
    Map<String, dynamic> budgetData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final budgetId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final data = {
        'budget_id_232143': budgetId,
        'user_id_232143': userId,
        'category_id_232143': budgetData['category_id'],
        'amount_232143': budgetData['amount'],
        'period_232143': budgetData['period'],
        'period_start_232143': budgetData['period_start'],
        'period_end_232143': budgetData['period_end'],
        'spent_amount_232143': 0.0,
        'remaining_amount_232143': budgetData['amount'],
        'rollover_enabled_232143':
            budgetData['rollover_enabled'] == true ? 1 : 0,
        'alert_threshold_232143': budgetData['alert_threshold'] ?? 80,
        'is_active_232143': budgetData['is_active'] == false ? 0 : 1,
        'created_at_232143': now,
        'updated_at_232143': now,
      };

      await db.insert('budgets_232143', data);
      LoggerService.info('✅ Budget added: $budgetId');
      return {'budget': data};
    } catch (e) {
      LoggerService.error('Error adding budget', error: e);
      rethrow;
    }
  }

  /// Delete budget
  Future<Map<String, dynamic>> deleteBudget(String budgetId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;

      final rowsDeleted = await db.delete(
        'budgets_232143',
        where: 'budget_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [budgetId, userId],
      );

      if (rowsDeleted > 0) {
        LoggerService.info('✅ Budget deleted: $budgetId');
        return {'success': true, 'message': 'Budget deleted successfully'};
      } else {
        return {'success': false, 'message': 'Budget not found'};
      }
    } catch (e) {
      LoggerService.error('Error deleting budget', error: e);
      rethrow;
    }
  }

  /// Update budget
  Future<Map<String, dynamic>> updateBudget(
    String budgetId,
    Map<String, dynamic> budgetData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final now = DateTime.now().toIso8601String();

      final data = {
        if (budgetData['category_id'] != null)
          'category_id_232143': budgetData['category_id'],
        if (budgetData['amount'] != null) 'amount_232143': budgetData['amount'],
        if (budgetData['period'] != null) 'period_232143': budgetData['period'],
        if (budgetData['period_start'] != null)
          'period_start_232143': budgetData['period_start'],
        if (budgetData['period_end'] != null)
          'period_end_232143': budgetData['period_end'],
        if (budgetData['is_active'] != null)
          'is_active_232143': budgetData['is_active'] ? 1 : 0,
        'updated_at_232143': now,
      };

      final rowsUpdated = await db.update(
        'budgets_232143',
        data,
        where: 'budget_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [budgetId, userId],
      );

      if (rowsUpdated > 0) {
        LoggerService.info('✅ Budget updated: $budgetId');
        return {'success': true, 'message': 'Budget updated successfully'};
      } else {
        return {'success': false, 'message': 'Budget not found'};
      }
    } catch (e) {
      LoggerService.error('Error updating budget', error: e);
      rethrow;
    }
  }

  // ==================== GOALS ====================

  /// Get goals
  Future<List<Map<String, dynamic>>> getGoals() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final goals = await db.query(
        'financial_goals_232143',
        where: 'user_id_232143 = ?',
        whereArgs: [userId],
        orderBy: 'priority_232143 DESC, target_date_232143 ASC',
      );

      return List<Map<String, dynamic>>.from(goals);
    } catch (e) {
      LoggerService.error('Error getting goals', error: e);
      rethrow;
    }
  }

  /// Add goal
  Future<Map<String, dynamic>> addGoal(Map<String, dynamic> goalData) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final goalId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final data = {
        'goal_id_232143': goalId,
        'user_id_232143': userId,
        'name_232143': goalData['name'],
        'description_232143': goalData['description'],
        'goal_type_232143': goalData['goal_type'],
        'target_amount_232143': goalData['target_amount'],
        'current_amount_232143': 0.0,
        'start_date_232143': goalData['start_date'] ?? now.split('T')[0],
        'target_date_232143': goalData['target_date'],
        'priority_232143': goalData['priority'] ?? 3,
        'created_at_232143': now,
        'updated_at_232143': now,
      };

      await db.insert('financial_goals_232143', data);
      LoggerService.info('✅ Goal added: $goalId');
      return {'goal': data};
    } catch (e) {
      LoggerService.error('Error adding goal', error: e);
      rethrow;
    }
  }

  /// Update goal
  Future<Map<String, dynamic>> updateGoal(
    String goalId,
    Map<String, dynamic> goalData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final now = DateTime.now().toIso8601String();

      final data = {
        if (goalData['name'] != null) 'name_232143': goalData['name'],
        if (goalData['description'] != null)
          'description_232143': goalData['description'],
        if (goalData['goal_type'] != null)
          'goal_type_232143': goalData['goal_type'],
        if (goalData['target_amount'] != null)
          'target_amount_232143': goalData['target_amount'],
        if (goalData['current_amount'] != null)
          'current_amount_232143': goalData['current_amount'],
        if (goalData['target_date'] != null)
          'target_date_232143': goalData['target_date'],
        if (goalData['priority'] != null)
          'priority_232143': goalData['priority'],
        if (goalData['is_completed'] != null)
          'is_completed_232143': goalData['is_completed'] ? 1 : 0,
        if (goalData['completed_date'] != null)
          'completed_date_232143': goalData['completed_date'],
        if (goalData['auto_deduct'] != null)
          'auto_deduct_232143': goalData['auto_deduct'] ? 1 : 0,
        if (goalData['deduct_percentage'] != null)
          'deduct_percentage_232143': goalData['deduct_percentage'],
        'updated_at_232143': now,
      };

      final rowsUpdated = await db.update(
        'financial_goals_232143',
        data,
        where: 'goal_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [goalId, userId],
      );

      if (rowsUpdated > 0) {
        LoggerService.info('✅ Goal updated: $goalId');
        return {'success': true, 'message': 'Goal updated successfully'};
      } else {
        return {'success': false, 'message': 'Goal not found'};
      }
    } catch (e) {
      LoggerService.error('Error updating goal', error: e);
      rethrow;
    }
  }

  /// Delete goal
  Future<Map<String, dynamic>> deleteGoal(String goalId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;

      final rowsDeleted = await db.delete(
        'financial_goals_232143',
        where: 'goal_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [goalId, userId],
      );

      if (rowsDeleted > 0) {
        LoggerService.info('✅ Goal deleted: $goalId');
        return {'success': true, 'message': 'Goal deleted successfully'};
      } else {
        return {'success': false, 'message': 'Goal not found'};
      }
    } catch (e) {
      LoggerService.error('Error deleting goal', error: e);
      rethrow;
    }
  }

  /// Add contribution to goal
  /// If [accountId] is provided, deducts from that account and creates a transaction
  Future<Map<String, dynamic>> addGoalContribution(
    String goalId,
    double amount, {
    String? accountId,
    String? note,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;

      final goal = await db.query(
        'financial_goals_232143',
        where: 'goal_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [goalId, userId],
      );

      if (goal.isEmpty) {
        throw Exception('Goal not found');
      }

      // If account is specified, deduct balance and create a transaction
      if (accountId != null && accountId.isNotEmpty) {
        // Check sufficient balance
        final accountResult = await db.query(
          'accounts_232143',
          where: 'account_id_232143 = ?',
          whereArgs: [accountId],
          limit: 1,
        );

        if (accountResult.isNotEmpty) {
          final currentBalance =
              (accountResult.first['balance_232143'] as num?)?.toDouble() ??
              0.0;
          if (currentBalance < amount) {
            throw Exception('Saldo tidak mencukupi');
          }

          // Deduct from account
          await _adjustAccountBalance(db, accountId, -amount);

          // Create an expense transaction for the contribution
          final txnId = _uuid.v4();
          final now = DateTime.now().toIso8601String();
          final goalName = goal.first['name_232143'] as String? ?? 'Goal';

          await db.insert('transactions_232143', {
            'transaction_id_232143': txnId,
            'user_id_232143': userId,
            'account_id_232143': accountId,
            'amount_232143': amount,
            'type_232143': 'expense',
            'description_232143': 'Kontribusi: $goalName',
            'transaction_date_232143': now.split('T')[0],
            'transaction_time_232143': now.split('T')[1],
            'created_at_232143': now,
            'updated_at_232143': now,
          });

          // Record in goal_contributions table
          await db.insert('goal_contributions_232143', {
            'contribution_id_232143': _uuid.v4(),
            'goal_id_232143': goalId,
            'account_id_232143': accountId,
            'amount_232143': amount,
            'contributed_at_232143': now,
            'note_232143': note,
          });
        }
      } else {
        // If no account, just record the contribution without account_id
        final now = DateTime.now().toIso8601String();
        await db.insert('goal_contributions_232143', {
          'contribution_id_232143': _uuid.v4(),
          'goal_id_232143': goalId,
          'amount_232143': amount,
          'contributed_at_232143': now,
          'note_232143': note,
        });
      }

      final currentAmount =
          (goal.first['current_amount_232143'] as num?)?.toDouble() ?? 0.0;
      final targetAmount =
          (goal.first['target_amount_232143'] as num?)?.toDouble() ?? 0.0;
      final newAmount = currentAmount + amount;
      final isCompleted = newAmount >= targetAmount;
      final now2 = DateTime.now().toIso8601String();

      await db.update(
        'financial_goals_232143',
        {
          'current_amount_232143': newAmount,
          'is_completed_232143': isCompleted ? 1 : 0,
          if (isCompleted) 'completed_date_232143': now2.split('T')[0],
          'updated_at_232143': now2,
        },
        where: 'goal_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [goalId, userId],
      );

      LoggerService.info(
        '✅ Goal contribution: $goalId +$amount${accountId != null ? ' (from account: $accountId)' : ''} (new: $newAmount/$targetAmount)',
      );
      return {
        'success': true,
        'message': 'Contribution added successfully',
        'new_amount': newAmount,
        'target_amount': targetAmount,
        'is_completed': isCompleted,
        'progress_percentage':
            targetAmount > 0 ? (newAmount / targetAmount * 100) : 0.0,
      };
    } catch (e) {
      LoggerService.error('Error adding goal contribution', error: e);
      rethrow;
    }
  }

  /// Get contributions for a specific goal
  Future<List<Map<String, dynamic>>> getGoalContributions(String goalId) async {
    try {
      final db = await _dbService.database;
      final contributions = await db.rawQuery(
        '''SELECT gc.*, a.name_232143 AS account_name, a.type_232143 AS account_type
        FROM goal_contributions_232143 gc
        LEFT JOIN accounts_232143 a ON gc.account_id_232143 = a.account_id_232143
        WHERE gc.goal_id_232143 = ?
        ORDER BY gc.contributed_at_232143 DESC''',
        [goalId],
      );
      return List<Map<String, dynamic>>.from(contributions);
    } catch (e) {
      LoggerService.error('Error getting goal contributions', error: e);
      return [];
    }
  }

  /// Get total contributed amount across all goals
  Future<double> getTotalGoalContributions() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return 0.0;

      final db = await _dbService.database;
      final result = await db.rawQuery(
        '''SELECT COALESCE(SUM(current_amount_232143), 0) as total
        FROM financial_goals_232143
        WHERE user_id_232143 = ?''',
        [userId],
      );
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      LoggerService.error('Error getting total goal contributions', error: e);
      return 0.0;
    }
  }

  // ==================== OBLIGATIONS ====================

  /// Get obligations
  Future<List<Map<String, dynamic>>> getObligations({String? type}) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      var where = 'user_id_232143 = ?';
      var whereArgs = <dynamic>[userId];

      // Note: type filtering would need additional field in schema
      // For now, we'll return all obligations

      final obligations = await db.query(
        'financial_obligations_232143',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'due_date_232143 ASC',
      );

      return List<Map<String, dynamic>>.from(obligations);
    } catch (e) {
      LoggerService.error('Error getting obligations', error: e);
      rethrow;
    }
  }

  /// Get upcoming obligations
  Future<List<Map<String, dynamic>>> getUpcomingObligations({
    int days = 7,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final now = DateTime.now();
      final endDate = now.add(Duration(days: days));

      final obligations = await db.query(
        'financial_obligations_232143',
        where:
            'user_id_232143 = ? AND due_date_232143 <= ? AND is_paid_232143 = 0',
        whereArgs: [userId, endDate.toIso8601String().split('T')[0]],
        orderBy: 'due_date_232143 ASC',
      );

      return List<Map<String, dynamic>>.from(obligations);
    } catch (e) {
      LoggerService.error('Error getting upcoming obligations', error: e);
      rethrow;
    }
  }

  /// Add obligation
  Future<Map<String, dynamic>> addObligation(
    Map<String, dynamic> obligationData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final obligationId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final data = {
        'obligation_id_232143': obligationId,
        'user_id_232143': userId,
        'name_232143': obligationData['name'],
        'description_232143': obligationData['description'],
        'amount_232143':
            obligationData['amount'] ?? obligationData['monthly_amount'] ?? 0.0,
        'due_date_232143':
            obligationData['due_date'] ?? obligationData['dueDate'],
        'frequency_232143': obligationData['frequency'] ?? 'monthly',
        'payment_method_232143': obligationData['payment_method'] ?? 'cash',
        'category_id_232143': obligationData['category_id'],
        'is_paid_232143': 0,
        'reminder_enabled_232143':
            obligationData['reminder_enabled'] == true ? 1 : 1,
        'reminder_days_before_232143':
            obligationData['reminder_days_before'] ?? 3,
        'auto_pay_enabled_232143':
            obligationData['auto_pay_enabled'] == true ? 1 : 0,
        'created_at_232143': now,
        'updated_at_232143': now,
      };

      await db.insert('financial_obligations_232143', data);
      LoggerService.info('✅ Obligation added: $obligationId');
      return {'obligation': data};
    } catch (e) {
      LoggerService.error('Error adding obligation', error: e);
      rethrow;
    }
  }

  /// Update obligation
  Future<Map<String, dynamic>> updateObligation(
    String obligationId,
    Map<String, dynamic> obligationData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final now = DateTime.now().toIso8601String();

      final data = <String, dynamic>{'updated_at_232143': now};

      if (obligationData.containsKey('name')) {
        data['name_232143'] = obligationData['name'];
      }
      if (obligationData.containsKey('description')) {
        data['description_232143'] = obligationData['description'];
      }
      if (obligationData.containsKey('amount') ||
          obligationData.containsKey('monthly_amount')) {
        data['amount_232143'] =
            obligationData['amount'] ?? obligationData['monthly_amount'];
      }
      if (obligationData.containsKey('due_date') ||
          obligationData.containsKey('dueDate')) {
        data['due_date_232143'] =
            obligationData['due_date'] ?? obligationData['dueDate'];
      }
      if (obligationData.containsKey('frequency')) {
        data['frequency_232143'] = obligationData['frequency'];
      }
      if (obligationData.containsKey('payment_method')) {
        data['payment_method_232143'] = obligationData['payment_method'];
      }
      if (obligationData.containsKey('category_id')) {
        data['category_id_232143'] = obligationData['category_id'];
      }
      if (obligationData.containsKey('is_paid')) {
        data['is_paid_232143'] = obligationData['is_paid'] == true ? 1 : 0;
        if (obligationData['is_paid'] == true) {
          data['paid_date_232143'] = now;
        }
      }
      if (obligationData.containsKey('reminder_enabled')) {
        data['reminder_enabled_232143'] =
            obligationData['reminder_enabled'] == true ? 1 : 0;
      }
      if (obligationData.containsKey('reminder_days_before')) {
        data['reminder_days_before_232143'] =
            obligationData['reminder_days_before'];
      }

      await db.update(
        'financial_obligations_232143',
        data,
        where: 'obligation_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [obligationId, userId],
      );

      LoggerService.info('✅ Obligation updated: $obligationId');
      final updated = await db.query(
        'financial_obligations_232143',
        where: 'obligation_id_232143 = ?',
        whereArgs: [obligationId],
        limit: 1,
      );
      return {'obligation': updated.isNotEmpty ? updated.first : {}};
    } catch (e) {
      LoggerService.error('Error updating obligation', error: e);
      rethrow;
    }
  }

  /// Delete obligation
  Future<Map<String, dynamic>> deleteObligation(String obligationId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      await db.delete(
        'financial_obligations_232143',
        where: 'obligation_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [obligationId, userId],
      );

      LoggerService.info('✅ Obligation deleted: $obligationId');
      return {'success': true};
    } catch (e) {
      LoggerService.error('Error deleting obligation', error: e);
      rethrow;
    }
  }

  /// Record obligation payment
  Future<Map<String, dynamic>> recordObligationPayment(
    String obligationId,
    Map<String, dynamic> paymentData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final now = DateTime.now().toIso8601String();

      // Update obligation as paid
      await db.update(
        'financial_obligations_232143',
        {
          'is_paid_232143': 1,
          'paid_date_232143': now,
          'updated_at_232143': now,
        },
        where: 'obligation_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [obligationId, userId],
      );

      LoggerService.info('✅ Obligation payment recorded: $obligationId');
      final updated = await db.query(
        'financial_obligations_232143',
        where: 'obligation_id_232143 = ?',
        whereArgs: [obligationId],
        limit: 1,
      );
      return {'obligation': updated.isNotEmpty ? updated.first : {}};
    } catch (e) {
      LoggerService.error('Error recording obligation payment', error: e);
      rethrow;
    }
  }

  /// Calculate obligations summary
  Map<String, dynamic> calculateObligationsSummary(List<dynamic> obligations) {
    double totalMonthly = 0.0;
    double totalDebt = 0.0;
    int activeCount = 0;
    int overdueCount = 0;
    final now = DateTime.now();

    for (var obligation in obligations) {
      final isPaid = obligation['is_paid_232143'] == 1;
      if (!isPaid) {
        activeCount++;
        final amount = (obligation['amount_232143'] as num?)?.toDouble() ?? 0.0;
        final frequency =
            obligation['frequency_232143']?.toString() ?? 'monthly';

        // Calculate monthly equivalent
        double monthlyAmount = 0.0;
        switch (frequency) {
          case 'monthly':
            monthlyAmount = amount;
            break;
          case 'yearly':
            monthlyAmount = amount / 12;
            break;
          case 'weekly':
            monthlyAmount = amount * 4.33;
            break;
          case 'daily':
            monthlyAmount = amount * 30;
            break;
          default:
            monthlyAmount = amount;
        }
        totalMonthly += monthlyAmount;
        totalDebt += amount;

        // Check if overdue
        final dueDateStr = obligation['due_date_232143']?.toString();
        if (dueDateStr != null) {
          try {
            final dueDate = DateTime.parse(dueDateStr);
            if (dueDate.isBefore(now)) {
              overdueCount++;
            }
          } catch (e) {
            LoggerService.warning('Error parsing due date', error: e);
          }
        }
      }
    }

    return {
      'total_monthly': totalMonthly,
      'total_debt': totalDebt,
      'active_count': activeCount,
      'overdue_count': overdueCount,
      'total_count': obligations.length,
    };
  }

  /// Get budgets by category ID
  /// Get budgets by category ID
  Future<List<Map<String, dynamic>>> getBudgetsByCategory(
    String categoryId,
  ) async {
    try {
      final db = await _dbService.database;
      final userId = await getCurrentUserId();

      if (userId == null) {
        LoggerService.warning('User not authenticated');
        return [];
      }

      final budgets = await db.query(
        'budgets_232143',
        where:
            'category_id_232143 = ? AND user_id_232143 = ? AND is_active_232143 = 1',
        whereArgs: [categoryId, userId],
      );

      LoggerService.debug(
        'Found ${budgets.length} budgets for category: $categoryId',
      );
      return budgets;
    } catch (e) {
      LoggerService.error('Error getting budgets by category', error: e);
      return [];
    }
  }

  /// Update budget spending amounts
  Future<void> updateBudgetSpending({
    required String budgetId,
    required double spentAmount,
    required double remainingAmount,
  }) async {
    try {
      final db = await _dbService.database;

      final rowsAffected = await db.update(
        'budgets_232143',
        {
          'spent_amount_232143': spentAmount,
          'remaining_amount_232143': remainingAmount,
          'updated_at_232143': DateTime.now().toIso8601String(),
        },
        where: 'budget_id_232143 = ?',
        whereArgs: [budgetId],
      );

      LoggerService.info(
        '✅ Budget updated: id=$budgetId, spent=$spentAmount, remaining=$remainingAmount, rows=$rowsAffected',
      );
    } catch (e) {
      LoggerService.error('Error updating budget spending', error: e);
      rethrow;
    }
  }

  /// Process budget rollover at period end
  /// Carries unused budget to the next period for enabled budgets
  Future<Map<String, dynamic>> processBudgetRollover() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final now = DateTime.now();
      int processedCount = 0;

      final rolloverBudgets = await db.query(
        'budgets_232143',
        where:
            'user_id_232143 = ? AND rollover_enabled_232143 = 1 AND is_active_232143 = 1 AND period_end_232143 < ?',
        whereArgs: [userId, now.toIso8601String()],
      );

      for (var budget in rolloverBudgets) {
        final budgetId = budget['budget_id_232143'] as String;
        final amount = (budget['amount_232143'] as num?)?.toDouble() ?? 0.0;
        final spent =
            (budget['spent_amount_232143'] as num?)?.toDouble() ?? 0.0;
        final remaining = amount - spent;
        final categoryId = budget['category_id_232143'] as String?;
        final period = budget['period_232143'] as String? ?? 'monthly';

        if (remaining <= 0) {
          await db.delete(
            'budgets_232143',
            where: 'budget_id_232143 = ?',
            whereArgs: [budgetId],
          );
          continue;
        }

        final newPeriodStart = now;
        DateTime newPeriodEnd;
        switch (period) {
          case 'weekly':
            newPeriodEnd = now.add(const Duration(days: 7));
            break;
          case 'monthly':
            newPeriodEnd = DateTime(now.year, now.month + 1, now.day);
            break;
          case 'yearly':
            newPeriodEnd = DateTime(now.year + 1, now.month, now.day);
            break;
          default:
            newPeriodEnd = now.add(const Duration(days: 30));
        }

        final newBudgetId = _uuid.v4();
        await db.insert('budgets_232143', {
          'budget_id_232143': newBudgetId,
          'user_id_232143': userId,
          'category_id_232143': categoryId,
          'amount_232143': amount + remaining,
          'period_232143': period,
          'period_start_232143': newPeriodStart.toIso8601String(),
          'period_end_232143': newPeriodEnd.toIso8601String(),
          'spent_amount_232143': 0.0,
          'rollover_enabled_232143': 1,
          'alert_threshold_232143': budget['alert_threshold_232143'] ?? 80,
          'is_active_232143': 1,
          'remaining_amount_232143': amount + remaining,
          'recommendation_reason_232143':
              'Rollover: Rp ${remaining.toStringAsFixed(0)} dari periode sebelumnya',
          'created_at_232143': now.toIso8601String(),
          'updated_at_232143': now.toIso8601String(),
        });

        await db.delete(
          'budgets_232143',
          where: 'budget_id_232143 = ?',
          whereArgs: [budgetId],
        );

        processedCount++;
      }

      LoggerService.info('✅ Processed rollover for $processedCount budgets');
      return {'success': true, 'processed_count': processedCount};
    } catch (e) {
      LoggerService.error('Error processing budget rollover', error: e);
      rethrow;
    }
  }

  /// Get spending trends for budget categories
  Future<List<Map<String, dynamic>>> getBudgetSpendingTrends({
    int months = 3,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final now = DateTime.now();

      final budgets = await db.query(
        'budgets_232143',
        where:
            'user_id_232143 = ? AND is_active_232143 = 1 AND category_id_232143 IS NOT NULL',
        whereArgs: [userId],
      );

      final trends = <Map<String, dynamic>>[];
      for (var budget in budgets) {
        final categoryId = budget['category_id_232143'] as String?;
        if (categoryId == null) continue;

        final categoryResult = await db.query(
          'categories_232143',
          where: 'category_id_232143 = ?',
          whereArgs: [categoryId],
          limit: 1,
        );
        final categoryName =
            categoryResult.isNotEmpty
                ? categoryResult.first['name_232143'] as String?
                : 'Lainnya';

        final monthlySpending = <Map<String, dynamic>>[];
        for (var i = 0; i < months; i++) {
          final monthStart = DateTime(now.year, now.month - i, 1);
          final monthEnd = DateTime(now.year, now.month - i + 1, 1);

          final spendingResult = await db.rawQuery(
            '''
            SELECT COALESCE(SUM(amount_232143), 0) as total
            FROM transactions_232143
            WHERE user_id_232143 = ? AND category_id_232143 = ?
            AND type_232143 = 'expense'
            AND transaction_date_232143 >= ? AND transaction_date_232143 < ?
            ''',
            [
              userId,
              categoryId,
              monthStart.toIso8601String().split('T')[0],
              monthEnd.toIso8601String().split('T')[0],
            ],
          );

          final total =
              (spendingResult.first['total'] as num?)?.toDouble() ?? 0.0;
          monthlySpending.add({
            'month': monthStart.month,
            'year': monthStart.year,
            'spent': total,
          });
        }

        final budgetAmount =
            (budget['amount_232143'] as num?)?.toDouble() ?? 0.0;
        final currentSpent =
            (budget['spent_amount_232143'] as num?)?.toDouble() ?? 0.0;
        final averages =
            monthlySpending.map((m) => m['spent'] as double).toList();
        final avgSpending =
            averages.isNotEmpty
                ? averages.reduce((a, b) => a + b) / averages.length
                : 0.0;

        trends.add({
          'budget_id': budget['budget_id_232143'],
          'category_id': categoryId,
          'category_name': categoryName,
          'budget_amount': budgetAmount,
          'current_spent': currentSpent,
          'avg_monthly_spending': avgSpending,
          'monthly_data': monthlySpending.reversed.toList(),
          'suggested_amount': (avgSpending * 1.1).clamp(
            budgetAmount * 0.5,
            budgetAmount * 2.0,
          ),
        });
      }

      return trends;
    } catch (e) {
      LoggerService.error('Error getting budget spending trends', error: e);
      rethrow;
    }
  }

  /// Save a receipt scan record
  Future<Map<String, dynamic>> saveReceiptScan(
    Map<String, dynamic> receiptData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final receiptId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final itemsJson =
          receiptData['items'] != null
              ? jsonEncode(receiptData['items'])
              : null;

      final data = {
        'receipt_id_232143': receiptId,
        'user_id_232143': userId,
        'image_path_232143': receiptData['image_path'],
        'merchant_232143': receiptData['merchant'],
        'total_amount_232143': receiptData['total_amount'] ?? 0.0,
        'receipt_date_232143': receiptData['receipt_date'],
        'raw_text_232143': receiptData['raw_text'],
        'items_json_232143': itemsJson,
        'category_id_232143': receiptData['category_id'],
        'transaction_id_232143': receiptData['transaction_id'],
        'is_processed_232143': receiptData['is_processed'] ?? 0,
        'confidence_score_232143': receiptData['confidence'] ?? 0.0,
        'created_at_232143': now,
        'updated_at_232143': now,
      };

      await db.insert('receipt_scans_232143', data);
      LoggerService.info('✅ Receipt scan saved: $receiptId');
      return {'receipt': data};
    } catch (e) {
      LoggerService.error('Error saving receipt scan', error: e);
      rethrow;
    }
  }

  /// Get all receipt scans
  Future<List<Map<String, dynamic>>> getReceiptScans({
    int limit = 50,
    int offset = 0,
    bool? processedOnly,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      var where = 'user_id_232143 = ?';
      var whereArgs = <dynamic>[userId];

      if (processedOnly != null) {
        where += ' AND is_processed_232143 = ?';
        whereArgs.add(processedOnly ? 1 : 0);
      }

      final scans = await db.query(
        'receipt_scans_232143',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'created_at_232143 DESC',
        limit: limit,
        offset: offset,
      );

      final scansWithItems =
          scans.map<Map<String, dynamic>>((scan) {
            final scanMap = Map<String, dynamic>.from(scan);
            final itemsJson = scanMap['items_json_232143'] as String?;
            if (itemsJson != null) {
              try {
                scanMap['items'] = jsonDecode(itemsJson);
              } catch (e) {
                scanMap['items'] = [];
              }
            } else {
              scanMap['items'] = [];
            }
            return scanMap;
          }).toList();

      return scansWithItems;
    } catch (e) {
      LoggerService.error('Error getting receipt scans', error: e);
      rethrow;
    }
  }

  /// Get a single receipt scan
  Future<Map<String, dynamic>?> getReceiptScan(String receiptId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final scans = await db.query(
        'receipt_scans_232143',
        where: 'receipt_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [receiptId, userId],
        limit: 1,
      );

      if (scans.isEmpty) return null;

      final scan = Map<String, dynamic>.from(scans.first);
      final itemsJson = scan['items_json_232143'] as String?;
      if (itemsJson != null) {
        try {
          scan['items'] = jsonDecode(itemsJson);
        } catch (e) {
          scan['items'] = [];
        }
      } else {
        scan['items'] = [];
      }
      return scan;
    } catch (e) {
      LoggerService.error('Error getting receipt scan', error: e);
      rethrow;
    }
  }

  /// Delete a receipt scan
  Future<Map<String, dynamic>> deleteReceiptScan(String receiptId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final scan = await db.query(
        'receipt_scans_232143',
        where: 'receipt_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [receiptId, userId],
        limit: 1,
      );

      if (scan.isEmpty) {
        return {'success': false, 'message': 'Receipt not found'};
      }

      final rowsDeleted = await db.delete(
        'receipt_scans_232143',
        where: 'receipt_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [receiptId, userId],
      );

      if (rowsDeleted > 0) {
        LoggerService.info('✅ Receipt scan deleted: $receiptId');
        return {'success': true, 'message': 'Receipt deleted successfully'};
      } else {
        return {'success': false, 'message': 'Receipt not found'};
      }
    } catch (e) {
      LoggerService.error('Error deleting receipt scan', error: e);
      rethrow;
    }
  }

  /// Update receipt scan linked transaction
  Future<Map<String, dynamic>> linkReceiptToTransaction(
    String receiptId,
    String transactionId,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final now = DateTime.now().toIso8601String();

      final rowsUpdated = await db.update(
        'receipt_scans_232143',
        {
          'transaction_id_232143': transactionId,
          'is_processed_232143': 1,
          'updated_at_232143': now,
        },
        where: 'receipt_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [receiptId, userId],
      );

      if (rowsUpdated > 0) {
        LoggerService.info(
          '✅ Receipt linked to transaction: $receiptId -> $transactionId',
        );
        return {'success': true, 'message': 'Receipt linked successfully'};
      } else {
        return {'success': false, 'message': 'Receipt not found'};
      }
    } catch (e) {
      LoggerService.error('Error linking receipt to transaction', error: e);
      rethrow;
    }
  }

  // ==================== ACCOUNTS ====================

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

      if (accountData.containsKey('name'))
        updateData['name_232143'] = accountData['name'];
      if (accountData.containsKey('type'))
        updateData['type_232143'] = accountData['type'];
      if (accountData.containsKey('icon'))
        updateData['icon_232143'] = accountData['icon'];
      if (accountData.containsKey('color'))
        updateData['color_232143'] = accountData['color'];
      if (accountData.containsKey('balance'))
        updateData['balance_232143'] = accountData['balance'];
      if (accountData.containsKey('currency'))
        updateData['currency_232143'] = accountData['currency'];
      if (accountData.containsKey('account_number'))
        updateData['account_number_232143'] = accountData['account_number'];
      if (accountData.containsKey('bank_name'))
        updateData['bank_name_232143'] = accountData['bank_name'];
      if (accountData.containsKey('is_active'))
        updateData['is_active_232143'] = accountData['is_active'] ? 1 : 0;
      if (accountData.containsKey('is_default'))
        updateData['is_default_232143'] = accountData['is_default'] ? 1 : 0;

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

  // ==================== DEBTS ====================

  Future<List<Map<String, dynamic>>> getDebts({bool activeOnly = true}) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      var where = 'user_id_232143 = ?';
      var whereArgs = <dynamic>[userId];

      if (activeOnly) {
        where += ' AND current_balance_232143 > 0';
      }

      final debts = await db.query(
        'debts_232143',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'due_date_232143 ASC',
      );

      return List<Map<String, dynamic>>.from(debts);
    } catch (e) {
      LoggerService.error('Error getting debts', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addDebt(Map<String, dynamic> debtData) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final debtId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final data = {
        'debt_id_232143': debtId,
        'user_id_232143': userId,
        'name_232143': debtData['name'],
        'original_amount_232143': debtData['original_amount'],
        'current_balance_232143': debtData['original_amount'],
        'interest_rate_232143': debtData['interest_rate'] ?? 0.0,
        'type_232143': debtData['type'] ?? 'personal',
        'start_date_232143': debtData['start_date'] ?? now.split('T')[0],
        'due_date_232143': debtData['due_date'],
        'monthly_payment_232143': debtData['monthly_payment'],
        'creditor_name_232143': debtData['creditor_name'],
        'notes_232143': debtData['notes'],
        'created_at_232143': now,
        'updated_at_232143': now,
      };

      await db.insert('debts_232143', data);
      LoggerService.info('✅ Debt added: $debtId');
      return {'debt': data};
    } catch (e) {
      LoggerService.error('Error adding debt', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> recordDebtPayment(
    String debtId,
    double amount, {
    String? notes,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final now = DateTime.now();

      final debtResult = await db.query(
        'debts_232143',
        where: 'debt_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [debtId, userId],
        limit: 1,
      );

      if (debtResult.isEmpty) throw Exception('Debt not found');

      final debt = debtResult.first;
      final currentBalance =
          (debt['current_balance_232143'] as num?)?.toDouble() ?? 0.0;
      final newBalance = (currentBalance - amount).clamp(0.0, currentBalance);

      await db.update(
        'debts_232143',
        {
          'current_balance_232143': newBalance,
          'updated_at_232143': now.toIso8601String(),
        },
        where: 'debt_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [debtId, userId],
      );

      final paymentId = _uuid.v4();
      await db.insert('debt_payments_232143', {
        'payment_id_232143': paymentId,
        'debt_id_232143': debtId,
        'user_id_232143': userId,
        'amount_232143': amount,
        'payment_date_232143': now.toIso8601String(),
        'balance_after_232143': newBalance,
        'notes_232143': notes,
        'created_at_232143': now.toIso8601String(),
      });

      LoggerService.info('✅ Debt payment recorded: $amount for $debtId');
      return {
        'success': true,
        'new_balance': newBalance,
        'payment_id': paymentId,
      };
    } catch (e) {
      LoggerService.error('Error recording debt payment', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getDebtPayments(String debtId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final payments = await db.query(
        'debt_payments_232143',
        where: 'debt_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [debtId, userId],
        orderBy: 'payment_date_232143 DESC',
      );

      return List<Map<String, dynamic>>.from(payments);
    } catch (e) {
      LoggerService.error('Error getting debt payments', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDebtSummary() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final result = await db.rawQuery(
        '''
        SELECT
          SUM(current_balance_232143) as total_debt,
          SUM(original_amount_232143) as total_original,
          COUNT(*) as debt_count
        FROM debts_232143
        WHERE user_id_232143 = ? AND current_balance_232143 > 0
        ''',
        [userId],
      );

      final row = result.first;
      final totalDebt = (row['total_debt'] as num?)?.toDouble() ?? 0.0;
      final totalOriginal = (row['total_original'] as num?)?.toDouble() ?? 0.0;

      return {
        'total_debt': totalDebt,
        'total_original': totalOriginal,
        'total_paid': totalOriginal - totalDebt,
        'debt_count': row['debt_count'] as int? ?? 0,
      };
    } catch (e) {
      LoggerService.error('Error getting debt summary', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteDebt(String debtId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final rowsDeleted = await db.delete(
        'debts_232143',
        where: 'debt_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [debtId, userId],
      );

      if (rowsDeleted > 0) {
        LoggerService.info('✅ Debt deleted: $debtId');
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Debt not found'};
      }
    } catch (e) {
      LoggerService.error('Error deleting debt', error: e);
      rethrow;
    }
  }

  // ==================== SUBSCRIPTIONS ====================

  Future<List<Map<String, dynamic>>> getSubscriptions({
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

      final subs = await db.query(
        'subscriptions_232143',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'next_renewal_232143 ASC',
      );

      return List<Map<String, dynamic>>.from(subs);
    } catch (e) {
      LoggerService.error('Error getting subscriptions', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addSubscription(
    Map<String, dynamic> subData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final subId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final data = {
        'subscription_id_232143': subId,
        'user_id_232143': userId,
        'name_232143': subData['name'],
        'cost_232143': subData['cost'],
        'cycle_232143': subData['cycle'] ?? 'monthly',
        'category_232143': subData['category'] ?? 'general',
        'start_date_232143': subData['start_date'] ?? now.split('T')[0],
        'next_renewal_232143': subData['next_renewal'],
        'is_active_232143': subData['is_active'] != false ? 1 : 0,
        'notes_232143': subData['notes'],
        'account_id_232143': subData['account_id'],
        'created_at_232143': now,
        'updated_at_232143': now,
      };

      await db.insert('subscriptions_232143', data);
      LoggerService.info('✅ Subscription added: $subId');
      return {'subscription': data};
    } catch (e) {
      LoggerService.error('Error adding subscription', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateSubscription(
    String subId,
    Map<String, dynamic> subData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final now = DateTime.now().toIso8601String();

      final updateData = <String, dynamic>{'updated_at_232143': now};

      if (subData.containsKey('name'))
        updateData['name_232143'] = subData['name'];
      if (subData.containsKey('cost'))
        updateData['cost_232143'] = subData['cost'];
      if (subData.containsKey('cycle'))
        updateData['cycle_232143'] = subData['cycle'];
      if (subData.containsKey('category'))
        updateData['category_232143'] = subData['category'];
      if (subData.containsKey('next_renewal'))
        updateData['next_renewal_232143'] = subData['next_renewal'];
      if (subData.containsKey('is_active'))
        updateData['is_active_232143'] = subData['is_active'] ? 1 : 0;
      if (subData.containsKey('notes'))
        updateData['notes_232143'] = subData['notes'];
      if (subData.containsKey('account_id'))
        updateData['account_id_232143'] = subData['account_id'];

      await db.update(
        'subscriptions_232143',
        updateData,
        where: 'subscription_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [subId, userId],
      );

      LoggerService.info('✅ Subscription updated: $subId');
      final updated = await db.query(
        'subscriptions_232143',
        where: 'subscription_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [subId, userId],
        limit: 1,
      );
      return {'subscription': updated.isNotEmpty ? updated.first : {}};
    } catch (e) {
      LoggerService.error('Error updating subscription', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteSubscription(String subId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final rowsDeleted = await db.delete(
        'subscriptions_232143',
        where: 'subscription_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [subId, userId],
      );

      if (rowsDeleted > 0) {
        LoggerService.info('✅ Subscription deleted: $subId');
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Subscription not found'};
      }
    } catch (e) {
      LoggerService.error('Error deleting subscription', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSubscriptionSummary() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final subs = await db.query(
        'subscriptions_232143',
        where: 'user_id_232143 = ? AND is_active_232143 = 1',
        whereArgs: [userId],
      );

      double totalMonthly = 0;
      final byCategory = <String, double>{};

      for (var sub in subs) {
        final cost = (sub['cost_232143'] as num?)?.toDouble() ?? 0.0;
        final cycle = sub['cycle_232143'] as String? ?? 'monthly';
        final category = sub['category_232143'] as String? ?? 'general';

        double monthlyCost;
        switch (cycle) {
          case 'weekly':
            monthlyCost = cost * 4.33;
            break;
          case 'yearly':
            monthlyCost = cost / 12;
            break;
          default:
            monthlyCost = cost;
        }

        totalMonthly += monthlyCost;
        byCategory[category] = (byCategory[category] ?? 0) + monthlyCost;
      }

      return {
        'total_monthly': totalMonthly,
        'total_yearly': totalMonthly * 12,
        'subscription_count': subs.length,
        'by_category': byCategory,
      };
    } catch (e) {
      LoggerService.error('Error getting subscription summary', error: e);
      rethrow;
    }
  }

  // ==================== TAGS ====================

  Future<List<Map<String, dynamic>>> getTags() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final tags = await db.query(
        'tags_232143',
        where: 'user_id_232143 = ?',
        whereArgs: [userId],
        orderBy: 'name_232143 ASC',
      );

      return List<Map<String, dynamic>>.from(tags);
    } catch (e) {
      LoggerService.error('Error getting tags', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addTag(Map<String, dynamic> tagData) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final tagId = _uuid.v4();

      await db.insert('tags_232143', {
        'tag_id_232143': tagId,
        'user_id_232143': userId,
        'name_232143': tagData['name'],
        'color_232143': tagData['color'] ?? '#8B5FBF',
        'created_at_232143': DateTime.now().toIso8601String(),
      });

      LoggerService.info('✅ Tag added: $tagId');
      return {
        'tag': {'tag_id_232143': tagId, ...tagData},
      };
    } catch (e) {
      LoggerService.error('Error adding tag', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteTag(String tagId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final rowsDeleted = await db.delete(
        'tags_232143',
        where: 'tag_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [tagId, userId],
      );

      if (rowsDeleted > 0) {
        LoggerService.info('✅ Tag deleted: $tagId');
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Tag not found'};
      }
    } catch (e) {
      LoggerService.error('Error deleting tag', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTransactionTags(
    String transactionId,
  ) async {
    try {
      final db = await _dbService.database;
      final result = await db.rawQuery(
        '''
        SELECT t.* FROM tags_232143 t
        INNER JOIN transaction_tags_232143 tt ON t.tag_id_232143 = tt.tag_id_232143
        WHERE tt.transaction_id_232143 = ?
        ''',
        [transactionId],
      );

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      LoggerService.error('Error getting transaction tags', error: e);
      rethrow;
    }
  }

  Future<void> addTransactionTag(String transactionId, String tagId) async {
    try {
      final db = await _dbService.database;
      await db.insert('transaction_tags_232143', {
        'transaction_id_232143': transactionId,
        'tag_id_232143': tagId,
      });
    } catch (e) {
      LoggerService.error('Error adding transaction tag', error: e);
      rethrow;
    }
  }

  Future<void> removeTransactionTag(String transactionId, String tagId) async {
    try {
      final db = await _dbService.database;
      await db.delete(
        'transaction_tags_232143',
        where: 'transaction_id_232143 = ? AND tag_id_232143 = ?',
        whereArgs: [transactionId, tagId],
      );
    } catch (e) {
      LoggerService.error('Error removing transaction tag', error: e);
      rethrow;
    }
  }

  // ==================== EXPENSE SPLITS ====================

  Future<List<Map<String, dynamic>>> getSplits({
    String? transactionId,
    bool activeOnly = true,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      var where = 'user_id_232143 = ?';
      var whereArgs = <dynamic>[userId];

      if (transactionId != null) {
        where += ' AND transaction_id_232143 = ?';
        whereArgs.add(transactionId);
      }

      if (activeOnly) {
        where += ' AND is_settled_232143 = 0';
      }

      final splits = await db.query(
        'expense_splits_232143',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'created_at_232143 DESC',
      );

      return List<Map<String, dynamic>>.from(splits);
    } catch (e) {
      LoggerService.error('Error getting splits', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addSplit(Map<String, dynamic> splitData) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final splitId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      await db.insert('expense_splits_232143', {
        'split_id_232143': splitId,
        'transaction_id_232143': splitData['transaction_id'],
        'user_id_232143': userId,
        'participant_name_232143': splitData['participant_name'],
        'participant_phone_232143': splitData['participant_phone'],
        'amount_232143': splitData['amount'],
        'paid_amount_232143': splitData['paid_amount'] ?? 0.0,
        'is_settled_232143': splitData['is_settled'] == true ? 1 : 0,
        'notes_232143': splitData['notes'],
        'created_at_232143': now,
      });

      LoggerService.info('✅ Split added: $splitId');
      return {
        'split': {'split_id_232143': splitId, ...splitData},
      };
    } catch (e) {
      LoggerService.error('Error adding split', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> settleSplit(String splitId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final now = DateTime.now().toIso8601String();

      await db.update(
        'expense_splits_232143',
        {'is_settled_232143': 1, 'settled_at_232143': now},
        where: 'split_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [splitId, userId],
      );

      LoggerService.info('✅ Split settled: $splitId');
      return {'success': true};
    } catch (e) {
      LoggerService.error('Error settling split', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteSplit(String splitId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final rowsDeleted = await db.delete(
        'expense_splits_232143',
        where: 'split_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [splitId, userId],
      );

      if (rowsDeleted > 0) {
        LoggerService.info('✅ Split deleted: $splitId');
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Split not found'};
      }
    } catch (e) {
      LoggerService.error('Error deleting split', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSplitSummary() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final result = await db.rawQuery(
        '''
        SELECT
          SUM(CASE WHEN is_settled_232143 = 0 THEN (amount_232143 - paid_amount_232143) ELSE 0 END) as total_owed,
          SUM(CASE WHEN is_settled_232143 = 1 THEN amount_232143 ELSE 0 END) as total_settled,
          SUM(CASE WHEN is_settled_232143 = 0 THEN 1 ELSE 0 END) as active_count,
          SUM(CASE WHEN is_settled_232143 = 1 THEN 1 ELSE 0 END) as settled_count
        FROM expense_splits_232143
        WHERE user_id_232143 = ?
        ''',
        [userId],
      );

      final row = result.first;
      return {
        'total_owed': (row['total_owed'] as num?)?.toDouble() ?? 0.0,
        'total_settled': (row['total_settled'] as num?)?.toDouble() ?? 0.0,
        'active_count': (row['active_count'] as int?) ?? 0,
        'settled_count': (row['settled_count'] as int?) ?? 0,
      };
    } catch (e) {
      LoggerService.error('Error getting split summary', error: e);
      rethrow;
    }
  }

  // ==================== INVESTMENTS ====================

  Future<List<Map<String, dynamic>>> getInvestments({String? type}) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      var where = 'user_id_232143 = ?';
      var whereArgs = <dynamic>[userId];

      if (type != null) {
        where += ' AND type_232143 = ?';
        whereArgs.add(type);
      }

      final investments = await db.query(
        'investments_232143',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'created_at_232143 DESC',
      );

      return List<Map<String, dynamic>>.from(investments);
    } catch (e) {
      LoggerService.error('Error getting investments', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addInvestment(
    Map<String, dynamic> invData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final invId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final data = {
        'investment_id_232143': invId,
        'user_id_232143': userId,
        'name_232143': invData['name'],
        'type_232143': invData['type'] ?? 'other',
        'quantity_232143': invData['quantity'],
        'buy_price_232143': invData['buy_price'],
        'current_price_232143':
            invData['current_price'] ?? invData['buy_price'],
        'buy_date_232143': invData['buy_date'] ?? now.split('T')[0],
        'ticker_232143': invData['ticker'],
        'notes_232143': invData['notes'],
        'created_at_232143': now,
        'updated_at_232143': now,
      };

      await db.insert('investments_232143', data);
      LoggerService.info('✅ Investment added: $invId');
      return {'investment': data};
    } catch (e) {
      LoggerService.error('Error adding investment', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateInvestmentPrice(
    String invId,
    double newPrice,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      await db.update(
        'investments_232143',
        {
          'current_price_232143': newPrice,
          'updated_at_232143': DateTime.now().toIso8601String(),
        },
        where: 'investment_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [invId, userId],
      );

      LoggerService.info('✅ Investment price updated: $invId');
      return {'success': true, 'new_price': newPrice};
    } catch (e) {
      LoggerService.error('Error updating investment price', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteInvestment(String invId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final rowsDeleted = await db.delete(
        'investments_232143',
        where: 'investment_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [invId, userId],
      );

      if (rowsDeleted > 0) {
        LoggerService.info('✅ Investment deleted: $invId');
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Investment not found'};
      }
    } catch (e) {
      LoggerService.error('Error deleting investment', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPortfolioSummary() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final investments = await db.query(
        'investments_232143',
        where: 'user_id_232143 = ?',
        whereArgs: [userId],
      );

      double totalValue = 0;
      double totalCost = 0;
      final byType = <String, dynamic>{};

      for (var inv in investments) {
        final quantity = (inv['quantity_232143'] as num?)?.toDouble() ?? 0.0;
        final buyPrice = (inv['buy_price_232143'] as num?)?.toDouble() ?? 0.0;
        final currentPrice =
            (inv['current_price_232143'] as num?)?.toDouble() ?? 0.0;
        final type = inv['type_232143'] as String? ?? 'other';

        final cost = quantity * buyPrice;
        final value = quantity * currentPrice;

        totalCost += cost;
        totalValue += value;

        byType[type] = {
          'value': (byType[type]?['value'] as double? ?? 0) + value,
          'cost': (byType[type]?['cost'] as double? ?? 0) + cost,
          'count': ((byType[type]?['count'] as int? ?? 0) + 1),
        };
      }

      final pnl = totalValue - totalCost;
      final pnlPercent = totalCost > 0 ? (pnl / totalCost) * 100 : 0;

      return {
        'total_value': totalValue,
        'total_cost': totalCost,
        'total_profit_loss': pnl,
        'total_profit_loss_percent': pnlPercent,
        'investment_count': investments.length,
        'by_type': byType,
      };
    } catch (e) {
      LoggerService.error('Error getting portfolio summary', error: e);
      rethrow;
    }
  }

  // ==================== CHALLENGES ====================

  Future<List<Map<String, dynamic>>> getChallenges({
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

      final challenges = await db.query(
        'challenges_232143',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'end_date_232143 ASC',
      );

      return List<Map<String, dynamic>>.from(challenges);
    } catch (e) {
      LoggerService.error('Error getting challenges', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addChallenge(
    Map<String, dynamic> challengeData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final challengeId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final data = {
        'challenge_id_232143': challengeId,
        'user_id_232143': userId,
        'name_232143': challengeData['name'],
        'description_232143': challengeData['description'],
        'type_232143': challengeData['type'] ?? 'custom',
        'target_amount_232143': challengeData['target_amount'],
        'current_amount_232143': challengeData['current_amount'] ?? 0.0,
        'start_date_232143': challengeData['start_date'] ?? now.split('T')[0],
        'end_date_232143': challengeData['end_date'],
        'is_active_232143': challengeData['is_active'] != false ? 1 : 0,
        'streak_days_232143': challengeData['streak_days'] ?? 0,
        'notes_232143': challengeData['notes'],
        'created_at_232143': now,
        'updated_at_232143': now,
      };

      await db.insert('challenges_232143', data);
      LoggerService.info('✅ Challenge added: $challengeId');
      return {'challenge': data};
    } catch (e) {
      LoggerService.error('Error adding challenge', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateChallenge(
    String challengeId,
    Map<String, dynamic> challengeData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final now = DateTime.now().toIso8601String();

      final updateData = <String, dynamic>{'updated_at_232143': now};

      if (challengeData.containsKey('name'))
        updateData['name_232143'] = challengeData['name'];
      if (challengeData.containsKey('description'))
        updateData['description_232143'] = challengeData['description'];
      if (challengeData.containsKey('target_amount'))
        updateData['target_amount_232143'] = challengeData['target_amount'];
      if (challengeData.containsKey('current_amount'))
        updateData['current_amount_232143'] = challengeData['current_amount'];
      if (challengeData.containsKey('is_active'))
        updateData['is_active_232143'] = challengeData['is_active'] ? 1 : 0;
      if (challengeData.containsKey('is_completed')) {
        updateData['is_completed_232143'] =
            challengeData['is_completed'] ? 1 : 0;
        if (challengeData['is_completed'] == true) {
          updateData['completed_date_232143'] = now.split('T')[0];
        }
      }
      if (challengeData.containsKey('streak_days'))
        updateData['streak_days_232143'] = challengeData['streak_days'];

      await db.update(
        'challenges_232143',
        updateData,
        where: 'challenge_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [challengeId, userId],
      );

      LoggerService.info('✅ Challenge updated: $challengeId');
      return {'success': true};
    } catch (e) {
      LoggerService.error('Error updating challenge', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteChallenge(String challengeId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final rowsDeleted = await db.delete(
        'challenges_232143',
        where: 'challenge_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [challengeId, userId],
      );

      if (rowsDeleted > 0) {
        LoggerService.info('✅ Challenge deleted: $challengeId');
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Challenge not found'};
      }
    } catch (e) {
      LoggerService.error('Error deleting challenge', error: e);
      rethrow;
    }
  }

  // ==================== TRANSACTION TEMPLATES ====================

  Future<List<Map<String, dynamic>>> getTransactionTemplates() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final templates = await db.query(
        'transaction_templates_232143',
        where: 'user_id_232143 = ?',
        whereArgs: [userId],
        orderBy: 'name_232143 ASC',
      );

      return List<Map<String, dynamic>>.from(templates);
    } catch (e) {
      LoggerService.error('Error getting transaction templates', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addTransactionTemplate(
    Map<String, dynamic> templateData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final templateId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final data = {
        'template_id_232143': templateId,
        'user_id_232143': userId,
        'name_232143': templateData['name'],
        'amount_232143': templateData['amount'],
        'type_232143': templateData['type'],
        'category_id_232143': templateData['category_id'],
        'description_232143': templateData['description'],
        'payment_method_232143': templateData['payment_method'],
        'account_id_232143': templateData['account_id'],
        'is_recurring_232143': templateData['is_recurring'] == true ? 1 : 0,
        'recurrence_pattern_232143': templateData['recurrence_pattern'],
        'tags_232143': templateData['tags'],
        'created_at_232143': now,
        'updated_at_232143': now,
      };

      await db.insert('transaction_templates_232143', data);
      LoggerService.info('✅ Template added: $templateId');
      return {'template': data};
    } catch (e) {
      LoggerService.error('Error adding template', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteTransactionTemplate(
    String templateId,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final rowsDeleted = await db.delete(
        'transaction_templates_232143',
        where: 'template_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [templateId, userId],
      );

      if (rowsDeleted > 0) {
        LoggerService.info('✅ Template deleted: $templateId');
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Template not found'};
      }
    } catch (e) {
      LoggerService.error('Error deleting template', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createTransactionFromTemplate(
    String templateId,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final templates = await db.query(
        'transaction_templates_232143',
        where: 'template_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [templateId, userId],
        limit: 1,
      );

      if (templates.isEmpty) throw Exception('Template not found');

      final template = templates.first;
      final now = DateTime.now();

      final transactionData = {
        'amount': template['amount_232143'],
        'type': template['type_232143'],
        'category_id': template['category_id_232143'],
        'description': template['description_232143'],
        'payment_method': template['payment_method_232143'],
        'transaction_date': now.toIso8601String().split('T')[0],
        'transaction_time': now.toIso8601String().split('T')[1],
        'tags': template['tags_232143'],
      };

      return await addTransaction(transactionData);
    } catch (e) {
      LoggerService.error('Error creating transaction from template', error: e);
      rethrow;
    }
  }

  // ==================== NET WORTH ====================

  Future<Map<String, dynamic>> recordNetWorthSnapshot(
    Map<String, dynamic> snapshotData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final snapshotId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      await db.insert('net_worth_history_232143', {
        'snapshot_id_232143': snapshotId,
        'user_id_232143': userId,
        'snapshot_date_232143':
            snapshotData['snapshot_date'] ?? now.split('T')[0],
        'net_worth_232143': snapshotData['net_worth'],
        'total_assets_232143': snapshotData['total_assets'],
        'total_liabilities_232143': snapshotData['total_liabilities'],
        'asset_breakdown_232143':
            snapshotData['asset_breakdown'] != null
                ? json.encode(snapshotData['asset_breakdown'])
                : null,
        'liability_breakdown_232143':
            snapshotData['liability_breakdown'] != null
                ? json.encode(snapshotData['liability_breakdown'])
                : null,
        'created_at_232143': now,
      });

      LoggerService.info('✅ Net worth snapshot recorded: $snapshotId');
      return {'success': true, 'snapshot_id': snapshotId};
    } catch (e) {
      LoggerService.error('Error recording net worth snapshot', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getNetWorthHistory({
    int limit = 90,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final snapshots = await db.query(
        'net_worth_history_232143',
        where: 'user_id_232143 = ?',
        whereArgs: [userId],
        orderBy: 'snapshot_date_232143 DESC',
        limit: limit,
      );

      final history =
          List<Map<String, dynamic>>.from(snapshots).map((s) {
            final map = Map<String, dynamic>.from(s);
            final assetBreakdown = map['asset_breakdown_232143'] as String?;
            final liabilityBreakdown =
                map['liability_breakdown_232143'] as String?;

            if (assetBreakdown != null) {
              try {
                map['asset_breakdown'] = json.decode(assetBreakdown);
              } catch (e) {
                map['asset_breakdown'] = {};
              }
            }
            if (liabilityBreakdown != null) {
              try {
                map['liability_breakdown'] = json.decode(liabilityBreakdown);
              } catch (e) {
                map['liability_breakdown'] = {};
              }
            }
            return map;
          }).toList();

      return history;
    } catch (e) {
      LoggerService.error('Error getting net worth history', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getNetWorthTrend() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final result = await db.rawQuery(
        '''
        SELECT net_worth_232143, snapshot_date_232143
        FROM net_worth_history_232143
        WHERE user_id_232143 = ?
        ORDER BY snapshot_date_232143 ASC
        ''',
        [userId],
      );

      if (result.isEmpty) {
        return {'trend': 'no_data', 'change': 0.0};
      }

      final first =
          (result.first['net_worth_232143'] as num?)?.toDouble() ?? 0.0;
      final last = (result.last['net_worth_232143'] as num?)?.toDouble() ?? 0.0;
      final change = first != 0 ? ((last - first) / first.abs()) * 100 : 0.0;

      return {
        'trend':
            change > 0
                ? 'increasing'
                : change < 0
                ? 'decreasing'
                : 'stable',
        'change_percent': change,
        'start_value': first,
        'end_value': last,
        'data_points': result.length,
      };
    } catch (e) {
      LoggerService.error('Error getting net worth trend', error: e);
      rethrow;
    }
  }

  // ==================== EXCHANGE RATES ====================

  Future<Map<String, double>> getExchangeRates() async {
    try {
      final db = await _dbService.database;
      final rates = await db.query(
        'exchange_rates_232143',
        where: 'from_currency_232143 = ?',
        whereArgs: ['IDR'],
      );

      final rateMap = <String, double>{};
      for (var rate in rates) {
        final toCurrency = rate['to_currency_232143'] as String;
        final rateValue = (rate['rate_232143'] as num?)?.toDouble() ?? 1.0;
        rateMap[toCurrency] = rateValue;
      }

      if (rateMap.isEmpty) {
        rateMap['IDR'] = 1.0;
        rateMap['USD'] = 16000.0;
        rateMap['EUR'] = 17500.0;
        rateMap['GBP'] = 20300.0;
        rateMap['JPY'] = 106.0;
        rateMap['SGD'] = 11900.0;
        rateMap['MYR'] = 3500.0;
        rateMap['AUD'] = 10500.0;
      }

      return rateMap;
    } catch (e) {
      LoggerService.error('Error getting exchange rates', error: e);
      return {
        'IDR': 1.0,
        'USD': 16000.0,
        'EUR': 17500.0,
        'GBP': 20300.0,
        'JPY': 106.0,
        'SGD': 11900.0,
        'MYR': 3500.0,
        'AUD': 10500.0,
      };
    }
  }

  Future<void> updateExchangeRates(Map<String, double> rates) async {
    try {
      final db = await _dbService.database;
      final now = DateTime.now().toIso8601String();

      for (var entry in rates.entries) {
        // Use currency pair as the ID so rate updates replace the old record
        final rateId = 'IDR_${entry.key}';
        await db.insert('exchange_rates_232143', {
          'rate_id_232143': rateId,
          'from_currency_232143': 'IDR',
          'to_currency_232143': entry.key,
          'rate_232143': entry.value,
          'last_updated_232143': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      LoggerService.info('✅ Exchange rates updated');
    } catch (e) {
      LoggerService.error('Error updating exchange rates', error: e);
      rethrow;
    }
  }
}
