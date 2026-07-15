import 'package:uuid/uuid.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/data/debt_data_service.dart';
import 'package:financial_app/services/data/subscription_data_service.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/models/debt_model.dart';
import 'package:financial_app/models/subscription_model.dart';

/// Data service for Obligation CRUD operations.
/// Extracted from the monolithic LocalDataService facade.
class ObligationDataService {
  final LocalDatabaseService _dbService;
  final LocalAuthService _authService;
  final _uuid = const Uuid();

  DebtDataService get _debtService => getIt<DebtDataService>();
  SubscriptionDataService get _subscriptionService => getIt<SubscriptionDataService>();

  ObligationDataService({
    LocalDatabaseService? dbService,
    LocalAuthService? authService,
  }) : _dbService = dbService ?? LocalDatabaseService(),
       _authService = authService ?? LocalAuthService();

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    return await _authService.getCurrentUserId();
  }

  /// Get obligations
  Future<List<FinancialObligation>> getObligations({String? type}) async {
    final userId = await getCurrentUserId();
    if (userId == null) throw Exception('Not authenticated');

    final db = await _dbService.database;
    var where = 'user_id_232143 = ?';
    var whereArgs = <dynamic>[userId];

    final obligations = await db.query(
      'financial_obligations_232143',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'due_date_232143 ASC',
    );

    return obligations
        .map((row) => FinancialObligation.fromMap(row))
        .toList();
  }

  /// Get upcoming obligations
  Future<List<FinancialObligation>> getUpcomingObligations({
    int days = 7,
  }) async {
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

    return obligations
        .map((row) => FinancialObligation.fromMap(row))
        .toList();
  }

  /// Add obligation
  Future<FinancialObligation> addObligation(
    Map<String, dynamic> obligationData,
  ) async {
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
    return FinancialObligation.fromMap(data);
  }

  /// Update obligation
  Future<FinancialObligation> updateObligation(
    String obligationId,
    Map<String, dynamic> obligationData,
  ) async {
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

    final updated = await db.query(
      'financial_obligations_232143',
      where: 'obligation_id_232143 = ?',
      whereArgs: [obligationId],
      limit: 1,
    );
    if (updated.isEmpty) {
      throw Exception('Obligation not found after update');
    }
    return FinancialObligation.fromMap(updated.first);
  }

  /// Delete obligation
  Future<bool> deleteObligation(String obligationId) async {
    final userId = await getCurrentUserId();
    if (userId == null) throw Exception('Not authenticated');

    final db = await _dbService.database;
    final rowsDeleted = await db.delete(
      'financial_obligations_232143',
      where: 'obligation_id_232143 = ? AND user_id_232143 = ?',
      whereArgs: [obligationId, userId],
    );
    return rowsDeleted > 0;
  }

  /// Record obligation payment
  Future<Map<String, dynamic>> recordObligationPayment(
    String obligationId,
    Map<String, dynamic> paymentData,
  ) async {
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

    final updated = await db.query(
      'financial_obligations_232143',
      where: 'obligation_id_232143 = ?',
      whereArgs: [obligationId],
      limit: 1,
    );
    return {'obligation': updated.isNotEmpty ? updated.first : {}};
  }

  /// Calculate obligations summary
  Map<String, dynamic> calculateObligationsSummary(
    List<FinancialObligation> obligations,
  ) {
    double totalMonthly = 0.0;
    double totalDebt = 0.0;
    int activeCount = 0;
    int overdueCount = 0;
    final now = DateTime.now();

    for (var obligation in obligations) {
      activeCount++;
      totalMonthly += obligation.monthlyAmount;
      totalDebt += obligation.currentBalance ?? obligation.monthlyAmount;

      if (obligation.dueDate.isBefore(now)) {
        overdueCount++;
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

  // ====================================================================
  // Debt delegation methods (backed by DebtDataService internally)
  // ====================================================================

  /// Get debts
  Future<List<DebtModel>> getDebts({bool activeOnly = true}) =>
      _debtService.getDebts(activeOnly: activeOnly);

  /// Add debt
  Future<DebtModel> addDebt(Map<String, dynamic> debtData) =>
      _debtService.addDebt(debtData);

  /// Record debt payment
  Future<Map<String, dynamic>> recordDebtPayment(
    String debtId,
    double amount, {
    String? notes,
  }) => _debtService.recordDebtPayment(debtId, amount, notes: notes);

  /// Get debt payments
  Future<List<Map<String, dynamic>>> getDebtPayments(String debtId) =>
      _debtService.getDebtPayments(debtId);

  /// Get debt summary
  Future<Map<String, dynamic>> getDebtSummary() =>
      _debtService.getDebtSummary();

  /// Delete debt
  Future<bool> deleteDebt(String debtId) =>
      _debtService.deleteDebt(debtId);

  // ====================================================================
  // Subscription delegation methods (backed by SubscriptionDataService internally)
  // ====================================================================

  /// Get subscriptions
  Future<List<SubscriptionModel>> getSubscriptions({bool activeOnly = true}) =>
      _subscriptionService.getSubscriptions(activeOnly: activeOnly);

  /// Add subscription
  Future<SubscriptionModel> addSubscription(
    Map<String, dynamic> subData,
  ) => _subscriptionService.addSubscription(subData);

  /// Update subscription
  Future<SubscriptionModel> updateSubscription(
    String subId,
    Map<String, dynamic> subData,
  ) => _subscriptionService.updateSubscription(subId, subData);

  /// Delete subscription
  Future<bool> deleteSubscription(String subId) =>
      _subscriptionService.deleteSubscription(subId);

  /// Get subscription summary
  Future<Map<String, dynamic>> getSubscriptionSummary() =>
      _subscriptionService.getSubscriptionSummary();
}
