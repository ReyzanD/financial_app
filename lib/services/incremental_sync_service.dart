import 'package:financial_app/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk incremental data sync
/// Hanya sync data yang berubah sejak last sync
class IncrementalSyncService {
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _lastTransactionSyncKey = 'last_transaction_sync';
  static const String _lastBudgetSyncKey = 'last_budget_sync';
  static const String _lastGoalSyncKey = 'last_goal_sync';

  // Singleton pattern
  static final IncrementalSyncService _instance = IncrementalSyncService._internal();
  factory IncrementalSyncService() => _instance;
  IncrementalSyncService._internal();

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime(String syncType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_getSyncKey(syncType));
      if (timestamp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      LoggerService.error('[IncrementalSyncService] Error getting last sync time', error: e);
      return null;
    }
  }

  /// Update last sync timestamp
  Future<void> updateLastSyncTime(String syncType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_getSyncKey(syncType), now);
      LoggerService.debug('[IncrementalSyncService] Updated last sync time for $syncType');
    } catch (e) {
      LoggerService.error('[IncrementalSyncService] Error updating sync time', error: e);
    }
  }

  /// Get sync key for specific type
  String _getSyncKey(String syncType) {
    switch (syncType) {
      case 'transactions':
        return _lastTransactionSyncKey;
      case 'budgets':
        return _lastBudgetSyncKey;
      case 'goals':
        return _lastGoalSyncKey;
      default:
        return _lastSyncKey;
    }
  }

  /// Check if sync is needed (based on last sync time)
  Future<bool> isSyncNeeded(String syncType, {Duration? maxAge}) async {
    try {
      final lastSync = await getLastSyncTime(syncType);
      if (lastSync == null) return true; // Never synced

      final maxAgeDuration = maxAge ?? const Duration(minutes: 5);
      final age = DateTime.now().difference(lastSync);
      return age > maxAgeDuration;
    } catch (e) {
      LoggerService.error('[IncrementalSyncService] Error checking sync need', error: e);
      return true; // Default to sync on error
    }
  }

  /// Sync transactions incrementally
  Future<List<dynamic>> syncTransactions({
    required Future<List<dynamic>> Function(DateTime? since) fetchFunction,
  }) async {
    try {
      final lastSync = await getLastSyncTime('transactions');
      LoggerService.debug(
        '[IncrementalSyncService] Syncing transactions since: ${lastSync ?? "never"}',
      );

      final newTransactions = await fetchFunction(lastSync);
      
      await updateLastSyncTime('transactions');
      
      LoggerService.success(
        '[IncrementalSyncService] Synced ${newTransactions.length} new transactions',
      );
      
      return newTransactions;
    } catch (e) {
      LoggerService.error('[IncrementalSyncService] Error syncing transactions', error: e);
      rethrow;
    }
  }

  /// Sync budgets incrementally
  Future<List<dynamic>> syncBudgets({
    required Future<List<dynamic>> Function(DateTime? since) fetchFunction,
  }) async {
    try {
      final lastSync = await getLastSyncTime('budgets');
      LoggerService.debug(
        '[IncrementalSyncService] Syncing budgets since: ${lastSync ?? "never"}',
      );

      final newBudgets = await fetchFunction(lastSync);
      
      await updateLastSyncTime('budgets');
      
      LoggerService.success(
        '[IncrementalSyncService] Synced ${newBudgets.length} new/updated budgets',
      );
      
      return newBudgets;
    } catch (e) {
      LoggerService.error('[IncrementalSyncService] Error syncing budgets', error: e);
      rethrow;
    }
  }

  /// Sync goals incrementally
  Future<List<dynamic>> syncGoals({
    required Future<List<dynamic>> Function(DateTime? since) fetchFunction,
  }) async {
    try {
      final lastSync = await getLastSyncTime('goals');
      LoggerService.debug(
        '[IncrementalSyncService] Syncing goals since: ${lastSync ?? "never"}',
      );

      final newGoals = await fetchFunction(lastSync);
      
      await updateLastSyncTime('goals');
      
      LoggerService.success(
        '[IncrementalSyncService] Synced ${newGoals.length} new/updated goals',
      );
      
      return newGoals;
    } catch (e) {
      LoggerService.error('[IncrementalSyncService] Error syncing goals', error: e);
      rethrow;
    }
  }

  /// Clear all sync timestamps (for full sync)
  Future<void> clearAllSyncTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSyncKey);
      await prefs.remove(_lastTransactionSyncKey);
      await prefs.remove(_lastBudgetSyncKey);
      await prefs.remove(_lastGoalSyncKey);
      LoggerService.info('[IncrementalSyncService] All sync timestamps cleared');
    } catch (e) {
      LoggerService.error('[IncrementalSyncService] Error clearing sync times', error: e);
    }
  }
}

