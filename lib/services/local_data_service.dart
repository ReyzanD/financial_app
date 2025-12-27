import 'package:uuid/uuid.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'dart:convert';

/// Local Data Service - Replaces all API calls with local database operations
class LocalDataService {
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final LocalAuthService _authService = LocalAuthService();
  final _uuid = const Uuid();

  /// Get current user ID
  Future<String?> _getCurrentUserId() async {
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
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      var where = 'user_id_232143 = ?';
      var whereArgs = <dynamic>[userId];

      if (type != null) {
        where += ' AND type_232143 = ?';
        whereArgs.add(type);
      }
      if (categoryId != null) {
        where += ' AND category_id_232143 = ?';
        whereArgs.add(categoryId);
      }
      if (startDate != null) {
        where += ' AND transaction_date_232143 >= ?';
        whereArgs.add(startDate);
      }
      if (endDate != null) {
        where += ' AND transaction_date_232143 <= ?';
        whereArgs.add(endDate);
      }
      if (search != null && search.isNotEmpty) {
        where += ' AND description_232143 LIKE ?';
        whereArgs.add('%$search%');
      }

      // Get total count
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM transactions_232143 WHERE $where',
        whereArgs,
      );
      final total = countResult.first['count'] as int;

      // Get transactions
      final transactions = await db.query(
        'transactions_232143',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'transaction_date_232143 DESC, created_at_232143 DESC',
        limit: limit,
        offset: offset,
      );

      return {
        'transactions': transactions,
        'total': total,
        'count': transactions.length,
        'has_more': (offset + transactions.length) < total,
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
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final transactions = await db.query(
        'transactions_232143',
        where: 'transaction_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [id, userId],
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
      final userId = await _getCurrentUserId();
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
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final now = DateTime.now().toIso8601String();

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

      await db.update(
        'transactions_232143',
        updateData,
        where: 'transaction_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [id, userId],
      );

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
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
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

  /// Get financial summary
  Future<Map<String, dynamic>> getFinancialSummary({
    int? year,
    int? month,
  }) async {
    try {
      final userId = await _getCurrentUserId();
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
      final userId = await _getCurrentUserId();
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
      final userId = await _getCurrentUserId();
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
      final userId = await _getCurrentUserId();
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
      final userId = await _getCurrentUserId();
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
      final userId = await _getCurrentUserId();
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
      final userId = await _getCurrentUserId();
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
        'is_active_232143': 1,
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

  // ==================== GOALS ====================

  /// Get goals
  Future<List<Map<String, dynamic>>> getGoals() async {
    try {
      final userId = await _getCurrentUserId();
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
      final userId = await _getCurrentUserId();
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

  // ==================== OBLIGATIONS ====================

  /// Get obligations
  Future<List<Map<String, dynamic>>> getObligations({String? type}) async {
    try {
      final userId = await _getCurrentUserId();
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
      final userId = await _getCurrentUserId();
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
      final userId = await _getCurrentUserId();
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
      final userId = await _getCurrentUserId();
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
      final userId = await _getCurrentUserId();
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
      final userId = await _getCurrentUserId();
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
}
