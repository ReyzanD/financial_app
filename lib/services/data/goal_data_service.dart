import 'package:uuid/uuid.dart';
import 'package:financial_app/models/goal_model.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/data/account_data_service.dart';
import 'package:financial_app/services/logger_service.dart';

/// Data service for Financial Goal CRUD operations.
class GoalDataService {
  final LocalDatabaseService _dbService;
  final LocalAuthService _authService;
  final AccountDataService _accountData;
  final _uuid = const Uuid();

  GoalDataService({
    LocalDatabaseService? dbService,
    LocalAuthService? authService,
    AccountDataService? accountData,
  }) : _dbService = dbService ?? LocalDatabaseService(),
       _authService = authService ?? LocalAuthService(),
       _accountData = accountData ?? AccountDataService();

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    return await _authService.getCurrentUserId();
  }

  /// Get goals
  Future<List<GoalModel>> getGoals() async {
    final userId = await getCurrentUserId();
    if (userId == null) throw Exception('Not authenticated');

    final db = await _dbService.database;
    final goals = await db.query(
      'financial_goals_232143',
      where: 'user_id_232143 = ?',
      whereArgs: [userId],
      orderBy: 'priority_232143 DESC, target_date_232143 ASC',
    );

    return goals.map((g) => GoalModel.fromMap(g)).toList();
  }

  /// Add goal
  Future<GoalModel> addGoal(Map<String, dynamic> goalData) async {
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
      'monthly_target_232143': goalData['monthly_target'],
      'created_at_232143': now,
      'updated_at_232143': now,
    };

    await db.insert('financial_goals_232143', data);
    return GoalModel.fromMap(data);
  }

  /// Update goal
  Future<GoalModel> updateGoal(
    String goalId,
    Map<String, dynamic> goalData,
  ) async {
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
      if (goalData['priority'] != null) 'priority_232143': goalData['priority'],
      if (goalData['monthly_target'] != null)
        'monthly_target_232143': goalData['monthly_target'],
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

    if (rowsUpdated == 0) {
      throw Exception('Goal not found');
    }

    // Re-fetch the updated record
    final updatedGoals = await db.query(
      'financial_goals_232143',
      where: 'goal_id_232143 = ? AND user_id_232143 = ?',
      whereArgs: [goalId, userId],
    );

    if (updatedGoals.isEmpty) {
      throw Exception('Goal not found after update');
    }

    return GoalModel.fromMap(updatedGoals.first);
  }

  /// Delete goal
  Future<bool> deleteGoal(String goalId) async {
    final userId = await getCurrentUserId();
    if (userId == null) throw Exception('Not authenticated');

    final db = await _dbService.database;

    final rowsDeleted = await db.delete(
      'financial_goals_232143',
      where: 'goal_id_232143 = ? AND user_id_232143 = ?',
      whereArgs: [goalId, userId],
    );

    return rowsDeleted > 0;
  }

  /// Add contribution to goal
  /// If [accountId] is provided, deducts from that account and creates a transaction
  Future<Map<String, dynamic>> addGoalContribution(
    String goalId,
    double amount, {
    String? accountId,
    String? note,
  }) async {
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
            (accountResult.first['balance_232143'] as num?)?.toDouble() ?? 0.0;
        if (currentBalance < amount) {
          throw Exception('Saldo tidak mencukupi');
        }

        // Deduct from account
        await _accountData.adjustAccountBalance(db, accountId, -amount);

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

    return {
      'success': true,
      'message': 'Contribution added successfully',
      'new_amount': newAmount,
      'target_amount': targetAmount,
      'is_completed': isCompleted,
      'progress_percentage':
          targetAmount > 0 ? (newAmount / targetAmount * 100) : 0.0,
    };
  }

  /// Get contributions for a specific goal
  Future<List<Map<String, dynamic>>> getGoalContributions(String goalId) async {
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
}
