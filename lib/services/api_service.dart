import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/budget_recommendation_service.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';
import 'package:financial_app/services/data/budget_data_service.dart';
import 'package:financial_app/services/data/category_data_service.dart';
import 'package:financial_app/services/data/goal_data_service.dart';
import 'package:financial_app/services/data/obligation_data_service.dart';
import 'package:financial_app/models/budget_model.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/models/goal_model.dart';

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
  final LocalAuthService _authService;
  final TransactionDataService _transactionData;
  final BudgetDataService _budgetData;
  final CategoryDataService _categoryData;
  final GoalDataService _goalData;
  final ObligationDataService _obligationData;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService({
    LocalAuthService? authService,
    TransactionDataService? transactionData,
    BudgetDataService? budgetData,
    CategoryDataService? categoryData,
    GoalDataService? goalData,
    ObligationDataService? obligationData,
  }) : _authService = authService ?? LocalAuthService(),
       _transactionData = transactionData ?? getIt<TransactionDataService>(),
       _budgetData = budgetData ?? getIt<BudgetDataService>(),
       _categoryData = categoryData ?? getIt<CategoryDataService>(),
       _goalData = goalData ?? getIt<GoalDataService>(),
       _obligationData = obligationData ?? getIt<ObligationDataService>();

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
    final user = await _authService.getCurrentUser();
    if (user == null) throw Exception('Not authenticated');
    return {'user': user};
  }

  // Update User Profile - Using local database
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    return await _authService.updateProfile(profileData);
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
    return await _transactionData.getTransactions(
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
      final result = await _transactionData.getFinancialSummary(
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
  Future<List<BudgetModel>> getBudgets({bool activeOnly = true}) async {
    return await _budgetData.getBudgets(activeOnly: activeOnly);
  }

  Future<Map<String, dynamic>> getBudget(String budgetId) async {
    final budgets = await _budgetData.getBudgets(activeOnly: false);
    final budget = budgets.where((b) => b.id == budgetId);
    return {'budget': budget.isNotEmpty ? budget.first.toJson() : <String, dynamic>{}};
  }

  Future<Map<String, dynamic>> createBudget(
    Map<String, dynamic> budgetData,
  ) async {
    final result = await _budgetData.addBudget(budgetData);
    return result.toJson();
  }

  Future<Map<String, dynamic>> updateBudget(
    String budgetId,
    Map<String, dynamic> budgetData,
  ) async {
    final result = await _budgetData.updateBudget(budgetId, budgetData);
    return result?.toJson() ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> deleteBudget(String budgetId) async {
    final success = await _budgetData.deleteBudget(budgetId);
    return {'success': success, 'message': success ? 'Budget deleted successfully' : 'Budget not found'};
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
  Map<String, dynamic> _calculateBudgetsSummary(List<BudgetModel> budgets) {
    double totalAmount = 0.0;
    double totalSpent = 0.0;
    int overBudgetCount = 0;
    int activeBudgets = 0;

    for (var budget in budgets) {
      if (budget.isActive) {
        activeBudgets++;
        totalAmount += budget.amount;
        totalSpent += budget.spent;
        if (budget.isOverBudget) {
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

  // AI Recommendations - Using BudgetRecommendationService for local data
  Future<dynamic> getAIRecommendations() async {
    try {
      final recommendationService = getIt<BudgetRecommendationService>();
      final recommendations =
          await recommendationService.generateRecommendation();
      return {
        'recommendations': recommendations,
        'generated_at': DateTime.now().toIso8601String(),
        'source': 'local_budget_recommendation_service',
      };
    } catch (e) {
      LoggerService.warning(
        'AI recommendations failed, returning empty',
        error: e,
      );
      return {'recommendations': [], 'error': e.toString()};
    }
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
      final categories = await _categoryData.getCategories();

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
    final result = await _transactionData.addTransaction(transactionData);
    // Clear caches after adding transaction
    LoggerService.debug('Clearing transaction caches after add...');
    _clearTransactionCaches();
    clearCache(); // Clear cache
    return result.toJson();
  }

  // Update Transaction - Using local database
  Future<Map<String, dynamic>> updateTransaction(
    String transactionId,
    Map<String, dynamic> transactionData,
  ) async {
    try {
      LoggerService.debug('Updating transaction: $transactionId');
      final result = await _transactionData.updateTransaction(
        transactionId,
        transactionData,
      );
      // Clear caches after updating transaction
      LoggerService.debug('Clearing transaction caches after update...');
      _clearTransactionCaches();
      clearCache();
      return result.toJson();
    } catch (e) {
      LoggerService.error('Update error', error: e);
      rethrow;
    }
  }

  // Delete Transaction - Using local database
  Future<Map<String, dynamic>> deleteTransaction(String transactionId) async {
    try {
      LoggerService.debug('Deleting transaction: $transactionId');
      await _transactionData.deleteTransaction(transactionId);
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
  Future<List<GoalModel>> getGoals({bool includeCompleted = false}) async {
    return await _goalData.getGoals();
  }

  Future<Map<String, dynamic>> getGoal(String goalId) async {
    final goals = await _goalData.getGoals();
    final goal = goals.firstWhere(
      (g) => g.id == goalId,
      orElse: () => GoalModel(
        id: '',
        userId: '',
        name: '',
        goalType: 'other',
        targetAmount: 0.0,
        startDate: DateTime.now(),
        targetDate: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
    return {'goal': goal.toJson()};
  }

  Future<GoalModel> createGoal(Map<String, dynamic> goalData) async {
    return await _goalData.addGoal(goalData);
  }

  Future<GoalModel> updateGoal(
    String goalId,
    Map<String, dynamic> goalData,
  ) async {
    return await _goalData.updateGoal(goalId, goalData);
  }

  Future<bool> deleteGoal(String goalId) async {
    return await _goalData.deleteGoal(goalId);
  }

  /// Add money to a goal (contribution)
  /// If [accountId] is provided, deducts from that account and creates a transaction
  Future<Map<String, dynamic>> addGoalContribution(
    String goalId,
    double amount, {
    String? accountId,
    String? note,
  }) async {
    return await _goalData.addGoalContribution(
      goalId,
      amount,
      accountId: accountId,
      note: note,
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
        totalTarget += goal.targetAmount;
        totalCurrent += goal.currentAmount;
        if (goal.isCompleted) {
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
  Future<List<FinancialObligation>> getObligations({String? type}) async {
    final userId = await _storage.read(key: 'auth_token');
    if (userId == null) throw Exception('User not authenticated');
    return await _obligationData.getObligations(type: type);
  }

  Future<List<FinancialObligation>> getUpcomingObligations({int days = 7}) async {
    final userId = await _storage.read(key: 'auth_token');
    if (userId == null) throw Exception('User not authenticated');
    return await _obligationData.getUpcomingObligations(days: days);
  }

  Future<FinancialObligation> createObligation(
    Map<String, dynamic> obligationData,
  ) async {
    final userId = await _storage.read(key: 'auth_token');
    if (userId == null) throw Exception('User not authenticated');
    final result = await _obligationData.addObligation(obligationData);
    clearCache(); // Clear cache on mutations
    return result;
  }

  Future<FinancialObligation> updateObligation(
    String obligationId,
    Map<String, dynamic> obligationData,
  ) async {
    final userId = await _storage.read(key: 'auth_token');
    if (userId == null) throw Exception('User not authenticated');
    final result = await _obligationData.updateObligation(
      obligationId,
      obligationData,
    );
    clearCache(); // Clear cache on mutations
    return result;
  }

  Future<bool> deleteObligation(String obligationId) async {
    final userId = await _storage.read(key: 'auth_token');
    if (userId == null) throw Exception('User not authenticated');
    final result = await _obligationData.deleteObligation(obligationId);
    clearCache(); // Clear cache on mutations
    return result;
  }

  Future<Map<String, dynamic>> recordObligationPayment(
    String obligationId,
    Map<String, dynamic> paymentData,
  ) async {
    final userId = await _storage.read(key: 'auth_token');
    if (userId == null) throw Exception('User not authenticated');
    final result = await _obligationData.recordObligationPayment(
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
    final obligations = await _obligationData.getObligations();
    return _obligationData.calculateObligationsSummary(obligations);
  }

  // Recurring Transactions - Using local database
  Future<List<dynamic>> getRecurringTransactions({
    bool activeOnly = true,
  }) async {
    // Get recurring transactions from local database
    final transactions = await _transactionData.getTransactions(limit: 1000);
    var recurring =
        (transactions['transactions'] as List)
            .where((t) => (t['is_recurring_232143'] as int? ?? 0) == 1)
            .toList();
    return recurring;
  }

  Future<Map<String, dynamic>> getRecurringTransaction(String id) async {
    final transaction = await _transactionData.getTransaction(id);
    return {'recurring_transaction': transaction?.toJson() ?? <String, dynamic>{}};
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
    final transactions = await _transactionData.getTransactions(
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
