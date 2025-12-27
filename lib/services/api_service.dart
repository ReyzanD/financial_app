import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/local_data_service.dart';

/// API Service - Main facade for all API operations
///
/// This service provides a unified interface for all data operations.
/// It now uses local database (no backend server required).
/// All operations are performed locally using SQLite.
///
/// Features:
/// - Automatic token management (user_id stored as token)
/// - Response caching (2-minute TTL)
/// - Error handling and logging
/// - Request/response transformation
///
/// Usage:
/// ```dart
/// final apiService = ApiService();
/// final transactions = await apiService.getTransactions(limit: 50);
/// ```
///
/// Author: Financial App Team
/// Last Updated: 2024
class ApiService {
  final LocalDataService _localData = LocalDataService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Cache layer for frequently accessed data
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Public methods for use by other services
  Future<Map<String, String>> getHeaders() async {
    return await _getHeaders();
  }

  // Clear specific cache or all
  static void clearCache([String? key]) {
    if (key != null) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    } else {
      _cache.clear();
      _cacheTimestamps.clear();

      // Clear all static caches (critical for logout to prevent data leakage)
      _cachedCategories = null;
      _categoriesCacheTime = null;
    }
  }

  // Clear instance-level caches (for when this service is reused)
  void clearInstanceCache() {
    _cachedSummary = null;
    _lastSummaryFetch = null;
    _cachedSummaryYear = null;
    _cachedSummaryMonth = null;
  }

  // User Profile - Using local database
  Future<Map<String, dynamic>> getUserProfile() async {
    final user = await _localData.authService.getCurrentUser();
    if (user == null) throw Exception('Not authenticated');
    return {'user': user};
  }

  // Update User Profile - Using local database
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    // TODO: Implement update profile in LocalAuthService
    throw Exception('Update profile not yet implemented in local database');
  }

  // Transactions - Using local database
  /// Get transactions with pagination support
  /// Returns a map with 'transactions' list and pagination metadata
  Future<Map<String, dynamic>> getTransactions({
    String? type,
    int limit = 10,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    double? minAmount,
    double? maxAmount,
    String? search,
  }) async {
    return await _localData.getTransactions(
      limit: limit,
      offset: offset,
      type: type,
      categoryId: categoryId,
      startDate: startDate?.toIso8601String().split('T')[0],
      endDate: endDate?.toIso8601String().split('T')[0],
      search: search,
    );
  }

  // Cache for financial summary
  Map<String, dynamic>? _cachedSummary;
  DateTime? _lastSummaryFetch;
  int? _cachedSummaryYear;
  int? _cachedSummaryMonth;
  static const _summaryTtl = Duration(minutes: 5);

  // Financial Summary - Delegated to TransactionApi
  Future<Map<String, dynamic>> getFinancialSummary({
    int? year,
    int? month,
  }) async {
    final now = DateTime.now();
    final targetYear = year ?? now.year;
    final targetMonth = month ?? now.month;

    if (_cachedSummary != null &&
        _lastSummaryFetch != null &&
        _cachedSummaryYear == targetYear &&
        _cachedSummaryMonth == targetMonth) {
      final age = DateTime.now().difference(_lastSummaryFetch!);
      if (age < _summaryTtl) {
        return _cachedSummary!;
      }
    }

    try {
      final result = await _localData.getFinancialSummary(
        year: targetYear,
        month: targetMonth,
      );

      _cachedSummary = result;
      _cachedSummaryYear = targetYear;
      _cachedSummaryMonth = targetMonth;
      _lastSummaryFetch = DateTime.now();

      return result;
    } catch (e) {
      if (_cachedSummary != null) {
        return _cachedSummary!;
      }
      rethrow;
    }
  }

  // Budgets - Using local database
  Future<List<dynamic>> getBudgets({bool activeOnly = true}) async {
    return await _localData.getBudgets(activeOnly: activeOnly);
  }

  Future<Map<String, dynamic>> getBudget(String budgetId) async {
    final budgets = await _localData.getBudgets(activeOnly: false);
    final budget = budgets.firstWhere(
      (b) => b['budget_id_232143'] == budgetId,
      orElse: () => {},
    );
    return {'budget': budget};
  }

  Future<Map<String, dynamic>> createBudget(
    Map<String, dynamic> budgetData,
  ) async {
    return await _localData.addBudget(budgetData);
  }

  Future<Map<String, dynamic>> updateBudget(
    String budgetId,
    Map<String, dynamic> budgetData,
  ) async {
    // TODO: Implement update budget in LocalDataService
    throw Exception('Update budget not yet implemented in local database');
  }

  Future<Map<String, dynamic>> deleteBudget(String budgetId) async {
    // TODO: Implement delete budget in LocalDataService
    throw Exception('Delete budget not yet implemented in local database');
  }

  Future<Map<String, dynamic>> getBudgetsSummary() async {
    try {
      // Calculate summary from local budgets
      final budgets = await getBudgets();
      final summary = _calculateBudgetsSummary(budgets);
      LoggerService.debug(
        'Calculated budgets summary: ${summary['total_budgets']} budgets, '
        '${summary['active_budgets']} active',
      );
      return summary;
    } catch (e) {
      LoggerService.error('Error calculating budgets summary', error: e);
      // Return empty summary as fallback
      return {
        'total_budgets': 0,
        'total_amount': 0.0,
        'total_spent': 0.0,
        'total_remaining': 0.0,
        'over_budget_count': 0,
        'active_budgets': 0,
        'average_usage_percent': 0.0,
      };
    }
  }

  /// Calculate budgets summary from budgets list
  Map<String, dynamic> _calculateBudgetsSummary(List<dynamic> budgets) {
    double totalAmount = 0.0;
    double totalSpent = 0.0;
    int overBudgetCount = 0;
    int activeBudgets = 0;

    for (var budget in budgets) {
      final amount = ((budget['amount'] as num?)?.toDouble() ?? 0.0);
      final spent = ((budget['spent'] as num?)?.toDouble() ?? 0.0);
      final isActive = budget['is_active'] as bool? ?? true;

      if (isActive) {
        activeBudgets++;
        totalAmount += amount;
        totalSpent += spent;
        if (spent > amount) {
          overBudgetCount++;
        }
      }
    }

    return {
      'total_budgets': budgets.length,
      'total_amount': totalAmount,
      'total_spent': totalSpent,
      'total_remaining': totalAmount - totalSpent,
      'over_budget_count': overBudgetCount,
      'active_budgets': activeBudgets,
      'average_usage_percent':
          totalAmount > 0 ? (totalSpent / totalAmount) * 100 : 0.0,
    };
  }

  // AI Recommendations - TODO: Implement in local database
  Future<dynamic> getAIRecommendations() async {
    // TODO: Implement AI recommendations using local data
    return {'recommendations': []};
  }

  // Cache for categories (5 minutes)
  static List<dynamic>? _cachedCategories;
  static DateTime? _categoriesCacheTime;
  static const _categoriesCacheDuration = Duration(minutes: 5);

  // Get Categories (with caching) - Using local database
  Future<List<dynamic>> getCategories({bool forceRefresh = false}) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh &&
        _cachedCategories != null &&
        _categoriesCacheTime != null &&
        DateTime.now().difference(_categoriesCacheTime!) <
            _categoriesCacheDuration) {
      LoggerService.cache('HIT', 'categories_232143');
      LoggerService.debug(
        'Using cached categories (${_cachedCategories!.length} items)',
      );
      return _cachedCategories!;
    }

    try {
      LoggerService.debug('Fetching categories from local database...');
      final categories = await _localData.getCategories();

      // Update cache
      _cachedCategories = categories;
      _categoriesCacheTime = DateTime.now();
      LoggerService.success('Categories cached: ${categories.length} items');

      return categories;
    } catch (e) {
      LoggerService.warning('Failed to fetch categories', error: e);
      // Return cached data if available, even if expired
      if (_cachedCategories != null) {
        LoggerService.debug('Returning stale cache as fallback');
        return _cachedCategories!;
      }
      rethrow;
    }
  }

  // Add Transaction - Using local database
  Future<Map<String, dynamic>> addTransaction(
    Map<String, dynamic> transactionData,
  ) async {
    final result = await _localData.addTransaction(transactionData);
    // Clear caches after adding transaction
    LoggerService.debug('Clearing transaction caches after add...');
    _clearTransactionCaches();
    clearCache(); // Clear cache
    return result;
  }

  // Update Transaction - Using local database
  Future<Map<String, dynamic>> updateTransaction(
    String transactionId,
    Map<String, dynamic> transactionData,
  ) async {
    try {
      LoggerService.debug('Updating transaction: $transactionId');
      final result = await _localData.updateTransaction(
        transactionId,
        transactionData,
      );
      // Clear caches after updating transaction
      LoggerService.debug('Clearing transaction caches after update...');
      _clearTransactionCaches();
      clearCache();
      return result;
    } catch (e) {
      LoggerService.error('Update error', error: e);
      rethrow;
    }
  }

  // Delete Transaction - Using local database
  Future<Map<String, dynamic>> deleteTransaction(String transactionId) async {
    try {
      LoggerService.debug('Deleting transaction: $transactionId');
      await _localData.deleteTransaction(transactionId);
      // Clear all transaction-related caches after deletion
      LoggerService.debug('Clearing transaction caches...');
      _clearTransactionCaches();
      clearCache();
      return {'message': 'Transaction deleted successfully'};
    } catch (e) {
      LoggerService.error('Delete error', error: e);
      rethrow;
    }
  }

  // Clear all transaction-related caches
  void _clearTransactionCaches() {
    // Clear all caches that contain transaction data
    final keysToRemove =
        _cache.keys
            .where(
              (key) =>
                  key.contains('transactions_232143') ||
                  key.contains('summary') ||
                  key.contains('analytics'),
            )
            .toList();

    for (var key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      LoggerService.debug('Cleared cache: $key');
    }

    // Also clear the old summary cache variables
    _cachedSummary = null;
    _lastSummaryFetch = null;
  }

  // Goals - Using local database
  Future<List<dynamic>> getGoals({bool includeCompleted = false}) async {
    return await _localData.getGoals();
  }

  Future<Map<String, dynamic>> getGoal(String goalId) async {
    final goals = await _localData.getGoals();
    final goal = goals.firstWhere(
      (g) => g['goal_id_232143'] == goalId,
      orElse: () => {},
    );
    return {'goal': goal};
  }

  Future<Map<String, dynamic>> createGoal(Map<String, dynamic> goalData) async {
    return await _localData.addGoal(goalData);
  }

  Future<Map<String, dynamic>> updateGoal(
    String goalId,
    Map<String, dynamic> goalData,
  ) async {
    // TODO: Implement update goal in LocalDataService
    throw Exception('Update goal not yet implemented in local database');
  }

  Future<Map<String, dynamic>> deleteGoal(String goalId) async {
    // TODO: Implement delete goal in LocalDataService
    throw Exception('Delete goal not yet implemented in local database');
  }

  /// Add money to a goal (contribution)
  Future<Map<String, dynamic>> addGoalContribution(
    String goalId,
    double amount,
  ) async {
    // TODO: Implement add contribution in LocalDataService
    throw Exception(
      'Add goal contribution not yet implemented in local database',
    );
  }

  Future<Map<String, dynamic>> getGoalsSummary() async {
    // Calculate summary from local goals
    try {
      final goals = await getGoals();
      double totalTarget = 0.0;
      double totalCurrent = 0.0;
      int completedCount = 0;

      for (var goal in goals) {
        totalTarget +=
            (goal['target_amount_232143'] as num?)?.toDouble() ?? 0.0;
        totalCurrent +=
            (goal['current_amount_232143'] as num?)?.toDouble() ?? 0.0;
        if (goal['is_completed_232143'] == 1) {
          completedCount++;
        }
      }

      return {
        'total_goals': goals.length,
        'total_target': totalTarget,
        'total_current': totalCurrent,
        'completed_count': completedCount,
        'overall_progress':
            totalTarget > 0 ? (totalCurrent / totalTarget * 100) : 0.0,
      };
    } catch (e) {
      LoggerService.error('Error calculating goals summary', error: e);
      return {
        'total_goals': 0,
        'total_target': 0.0,
        'total_current': 0.0,
        'completed_count': 0,
        'overall_progress': 0.0,
      };
    }
  }

  // Obligations - Using local database
  Future<List<dynamic>> getObligations({String? type}) async {
    final userId = await _storage.read(key: 'auth_token');
    if (userId == null) throw Exception('User not authenticated');
    return await _localData.getObligations(type: type);
  }

  Future<List<dynamic>> getUpcomingObligations({int days = 7}) async {
    final userId = await _storage.read(key: 'auth_token');
    if (userId == null) throw Exception('User not authenticated');
    return await _localData.getUpcomingObligations(days: days);
  }

  Future<Map<String, dynamic>> createObligation(
    Map<String, dynamic> obligationData,
  ) async {
    final userId = await _storage.read(key: 'auth_token');
    if (userId == null) throw Exception('User not authenticated');
    final result = await _localData.addObligation(obligationData);
    clearCache(); // Clear cache on mutations
    return result;
  }

  Future<Map<String, dynamic>> updateObligation(
    String obligationId,
    Map<String, dynamic> obligationData,
  ) async {
    final userId = await _storage.read(key: 'auth_token');
    if (userId == null) throw Exception('User not authenticated');
    final result = await _localData.updateObligation(
      obligationId,
      obligationData,
    );
    clearCache(); // Clear cache on mutations
    return result;
  }

  Future<Map<String, dynamic>> deleteObligation(String obligationId) async {
    final userId = await _storage.read(key: 'auth_token');
    if (userId == null) throw Exception('User not authenticated');
    final result = await _localData.deleteObligation(obligationId);
    clearCache(); // Clear cache on mutations
    return result;
  }

  Future<Map<String, dynamic>> recordObligationPayment(
    String obligationId,
    Map<String, dynamic> paymentData,
  ) async {
    final userId = await _storage.read(key: 'auth_token');
    if (userId == null) throw Exception('User not authenticated');
    final result = await _localData.recordObligationPayment(
      obligationId,
      paymentData,
    );
    clearCache(); // Clear cache on mutations
    return result;
  }

  /// Calculate obligations summary from obligations list
  Future<Map<String, dynamic>> getObligationsSummary() async {
    final userId = await _storage.read(key: 'auth_token');
    if (userId == null) throw Exception('User not authenticated');
    final obligations = await _localData.getObligations();
    return _localData.calculateObligationsSummary(obligations);
  }

  // Recurring Transactions - Using local database
  Future<List<dynamic>> getRecurringTransactions({
    bool activeOnly = true,
  }) async {
    // Get recurring transactions from local database
    final transactions = await _localData.getTransactions(limit: 1000);
    var recurring =
        (transactions['transactions'] as List)
            .where((t) => (t['is_recurring_232143'] as int? ?? 0) == 1)
            .toList();
    return recurring;
  }

  Future<Map<String, dynamic>> getRecurringTransaction(String id) async {
    final transaction = await _localData.getTransaction(id);
    return {'recurring_transaction': transaction ?? {}};
  }

  Future<Map<String, dynamic>> createRecurringTransaction(
    Map<String, dynamic> data,
  ) async {
    data['is_recurring'] = true;
    return await addTransaction(data);
  }

  Future<Map<String, dynamic>> updateRecurringTransaction(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await updateTransaction(id, data);
  }

  Future<void> deleteRecurringTransaction(String id) async {
    await deleteTransaction(id);
  }

  Future<Map<String, dynamic>> pauseRecurringTransaction(String id) async {
    return await updateTransaction(id, {'is_recurring': false});
  }

  Future<Map<String, dynamic>> resumeRecurringTransaction(String id) async {
    return await updateTransaction(id, {'is_recurring': true});
  }

  Future<List<dynamic>> getUpcomingRecurringTransactions({int days = 7}) async {
    // Get upcoming recurring transactions from local database
    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));
    final transactions = await _localData.getTransactions(
      limit: 1000,
      startDate: now.toIso8601String().split('T')[0],
      endDate: endDate.toIso8601String().split('T')[0],
    );
    var recurring =
        (transactions['transactions'] as List)
            .where((t) => (t['is_recurring_232143'] as int? ?? 0) == 1)
            .toList();
    return recurring;
  }
}
