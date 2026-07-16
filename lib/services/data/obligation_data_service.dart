import 'package:uuid/uuid.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/models/financial_obligation.dart';

/// Data service for Obligation CRUD operations.
/// Extracted from the monolithic LocalDataService facade.
class ObligationDataService {
  final LocalDatabaseService _dbService;
  final LocalAuthService _authService;
  final _uuid = const Uuid();

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

    return obligations.map((row) => FinancialObligation.fromMap(row)).toList();
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

    return obligations.map((row) => FinancialObligation.fromMap(row)).toList();
  }

  /// Add obligation (supports bill, debt, and subscription types)
  Future<FinancialObligation> addObligation(
    Map<String, dynamic> obligationData,
  ) async {
    final userId = await getCurrentUserId();
    if (userId == null) throw Exception('Not authenticated');

    final db = await _dbService.database;
    final obligationId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final data = <String, dynamic>{
      'obligation_id_232143': obligationId,
      'user_id_232143': userId,
      'name_232143': obligationData['name'],
      'description_232143': obligationData['description'],
      'amount_232143':
          obligationData['amount'] ?? obligationData['monthly_amount'] ?? 0.0,
      'due_date_232143':
          obligationData['due_date']?.toString() ??
          obligationData['dueDate']?.toString(),
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

    // Type-specific fields (bill/debt/subscription)
    if (obligationData.containsKey('type')) {
      data['type_232143'] = obligationData['type'];
    }
    if (obligationData.containsKey('category')) {
      data['category_232143'] = obligationData['category'];
    }
    if (obligationData.containsKey('original_amount')) {
      data['original_amount_232143'] = obligationData['original_amount'];
    }
    if (obligationData.containsKey('current_balance')) {
      data['current_balance_232143'] = obligationData['current_balance'];
    }
    if (obligationData.containsKey('interest_rate')) {
      data['interest_rate_232143'] = obligationData['interest_rate'];
    }
    if (obligationData.containsKey('minimum_payment')) {
      data['minimum_payment_232143'] = obligationData['minimum_payment'];
    }
    if (obligationData.containsKey('payoff_strategy')) {
      data['payoff_strategy_232143'] = obligationData['payoff_strategy'];
    }
    if (obligationData.containsKey('subscription_cycle')) {
      data['subscription_cycle_232143'] = obligationData['subscription_cycle'];
      data['is_subscription_232143'] = 1;
    }
    if (obligationData.containsKey('notes')) {
      data['notes_232143'] = obligationData['notes'];
    }
    if (obligationData.containsKey('is_active')) {
      data['is_active_232143'] = obligationData['is_active'] == true ? 1 : 0;
    }
    if (obligationData.containsKey('account_id')) {
      data['account_id_232143'] = obligationData['account_id'];
    }
    if (obligationData.containsKey('debt_type')) {
      data['debt_type_232143'] = obligationData['debt_type'];
    }
    if (obligationData.containsKey('creditor_name')) {
      data['creditor_name_232143'] = obligationData['creditor_name'];
    }
    if (obligationData.containsKey('next_renewal')) {
      data['next_renewal_232143'] = obligationData['next_renewal'];
    }

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
          obligationData['due_date']?.toString() ??
          obligationData['dueDate']?.toString();
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

    // Type-specific update fields
    if (obligationData.containsKey('type')) {
      data['type_232143'] = obligationData['type'];
    }
    if (obligationData.containsKey('category')) {
      data['category_232143'] = obligationData['category'];
    }
    if (obligationData.containsKey('original_amount')) {
      data['original_amount_232143'] = obligationData['original_amount'];
    }
    if (obligationData.containsKey('current_balance')) {
      data['current_balance_232143'] = obligationData['current_balance'];
    }
    if (obligationData.containsKey('interest_rate')) {
      data['interest_rate_232143'] = obligationData['interest_rate'];
    }
    if (obligationData.containsKey('minimum_payment')) {
      data['minimum_payment_232143'] = obligationData['minimum_payment'];
    }
    if (obligationData.containsKey('subscription_cycle')) {
      data['subscription_cycle_232143'] = obligationData['subscription_cycle'];
    }
    if (obligationData.containsKey('notes')) {
      data['notes_232143'] = obligationData['notes'];
    }
    if (obligationData.containsKey('is_active')) {
      data['is_active_232143'] = obligationData['is_active'] == true ? 1 : 0;
    }
    if (obligationData.containsKey('debt_type')) {
      data['debt_type_232143'] = obligationData['debt_type'];
    }
    if (obligationData.containsKey('creditor_name')) {
      data['creditor_name_232143'] = obligationData['creditor_name'];
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
      {'is_paid_232143': 1, 'paid_date_232143': now, 'updated_at_232143': now},
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
}
