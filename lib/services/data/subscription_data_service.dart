import 'package:uuid/uuid.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/models/subscription_model.dart';

/// Data service for Subscription CRUD operations.
/// Extracted from the monolithic LocalDataService facade.
class SubscriptionDataService {
  final LocalDatabaseService _dbService;
  final LocalAuthService _authService;
  final _uuid = const Uuid();

  SubscriptionDataService({
    LocalDatabaseService? dbService,
    LocalAuthService? authService,
  }) : _dbService = dbService ?? LocalDatabaseService(),
       _authService = authService ?? LocalAuthService();

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    return await _authService.getCurrentUserId();
  }

  /// Get subscriptions
  Future<List<SubscriptionModel>> getSubscriptions({
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

      return subs.map((m) => SubscriptionModel.fromMap(m)).toList();
    } catch (e) {
      LoggerService.error('Error getting subscriptions', error: e);
      rethrow;
    }
  }

  /// Add subscription
  Future<SubscriptionModel> addSubscription(
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
      return SubscriptionModel.fromMap(data);
    } catch (e) {
      LoggerService.error('Error adding subscription', error: e);
      rethrow;
    }
  }

  /// Update subscription
  Future<SubscriptionModel> updateSubscription(
    String subId,
    Map<String, dynamic> subData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final now = DateTime.now().toIso8601String();

      final updateData = <String, dynamic>{'updated_at_232143': now};

      if (subData.containsKey('name')) {
        updateData['name_232143'] = subData['name'];
      }
      if (subData.containsKey('cost')) {
        updateData['cost_232143'] = subData['cost'];
      }
      if (subData.containsKey('cycle')) {
        updateData['cycle_232143'] = subData['cycle'];
      }
      if (subData.containsKey('category')) {
        updateData['category_232143'] = subData['category'];
      }
      if (subData.containsKey('next_renewal')) {
        updateData['next_renewal_232143'] = subData['next_renewal'];
      }
      if (subData.containsKey('is_active')) {
        updateData['is_active_232143'] = subData['is_active'] ? 1 : 0;
      }
      if (subData.containsKey('notes')) {
        updateData['notes_232143'] = subData['notes'];
      }
      if (subData.containsKey('account_id')) {
        updateData['account_id_232143'] = subData['account_id'];
      }

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
      if (updated.isNotEmpty) {
        return SubscriptionModel.fromMap(updated.first);
      }
      throw Exception('Subscription not found after update');
    } catch (e) {
      LoggerService.error('Error updating subscription', error: e);
      rethrow;
    }
  }

  /// Delete subscription
  Future<bool> deleteSubscription(String subId) async {
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
      }
      return rowsDeleted > 0;
    } catch (e) {
      LoggerService.error('Error deleting subscription', error: e);
      rethrow;
    }
  }

  /// Get subscription summary
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
}
