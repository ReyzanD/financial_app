import 'package:uuid/uuid.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/logger_service.dart';

/// Data service for Budget CRUD operations.
/// Extracted from the monolithic LocalDataService facade.
class BudgetDataService {
  final LocalDatabaseService _dbService;
  final LocalAuthService _authService;
  final _uuid = const Uuid();

  BudgetDataService({
    LocalDatabaseService? dbService,
    LocalAuthService? authService,
  }) : _dbService = dbService ?? LocalDatabaseService(),
       _authService = authService ?? LocalAuthService();

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    return await _authService.getCurrentUserId();
  }

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

      final data = <String, dynamic>{
        if (budgetData['category_id'] != null)
          'category_id_232143': budgetData['category_id'],
        if (budgetData['amount'] != null)
          'amount_232143': budgetData['amount'],
        if (budgetData['period'] != null)
          'period_232143': budgetData['period'],
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

  /// When an expense is created, find the matching active budget for
  /// this category and update its spent/remaining amounts.
  /// Returns true if a budget was updated, false if no matching budget found.
  Future<bool> updateBudgetForExpense({
    required String categoryId,
    required double amount,
    required DateTime transactionDate,
  }) async {
    try {
      final budgets = await getBudgetsByCategory(categoryId);
      if (budgets.isEmpty) return false;

      // Find the budget whose period covers this transaction date
      Map<String, dynamic>? matchingBudget;
      for (final budget in budgets) {
        final periodStartStr = budget['period_start_232143']?.toString() ??
            budget['period_start']?.toString();
        final periodEndStr = budget['period_end_232143']?.toString() ??
            budget['period_end']?.toString();
        if (periodStartStr == null || periodEndStr == null) continue;

        final periodStart = DateTime.parse(periodStartStr);
        final periodEnd = DateTime.parse(periodEndStr);
        final txDate = DateTime(
          transactionDate.year,
          transactionDate.month,
          transactionDate.day,
        );

        if ((txDate.isAfter(periodStart) ||
                txDate.isAtSameMomentAs(periodStart)) &&
            (txDate.isBefore(periodEnd) ||
                txDate.isAtSameMomentAs(periodEnd))) {
          matchingBudget = budget;
          break;
        }
      }

      if (matchingBudget == null) return false;

      final budgetId = matchingBudget['budget_id_232143']?.toString() ??
          matchingBudget['budget_id']?.toString() ??
          '';
      if (budgetId.isEmpty) return false;

      final currentSpent =
          ((matchingBudget['spent_amount_232143'] ??
                      matchingBudget['spent_amount'] ??
                      0) as num)
              .toDouble();
      final budgetAmount =
          ((matchingBudget['amount_232143'] ?? matchingBudget['amount'] ?? 0)
                  as num)
              .toDouble();

      final newSpentAmount = currentSpent + amount;
      final newRemainingAmount = budgetAmount - newSpentAmount;

      await updateBudgetSpending(
        budgetId: budgetId,
        spentAmount: newSpentAmount,
        remainingAmount: newRemainingAmount,
      );

      LoggerService.info(
        '✅ Budget spending updated: $currentSpent → $newSpentAmount (added $amount)',
      );
      return true;
    } catch (e) {
      LoggerService.error('Error updating budget for expense', error: e);
      return false;
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
}
