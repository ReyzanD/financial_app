import 'package:uuid/uuid.dart';
import 'package:financial_app/models/debt_model.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/logger_service.dart';

/// Data service for Debt CRUD operations.
/// Extracted from the monolithic LocalDataService facade.
class DebtDataService {
  final LocalDatabaseService _dbService;
  final LocalAuthService _authService;
  final _uuid = const Uuid();

  DebtDataService({
    LocalDatabaseService? dbService,
    LocalAuthService? authService,
  }) : _dbService = dbService ?? LocalDatabaseService(),
       _authService = authService ?? LocalAuthService();

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    return await _authService.getCurrentUserId();
  }

  /// Get debts
  Future<List<DebtModel>> getDebts({bool activeOnly = true}) async {
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

      return debts.map((m) => DebtModel.fromMap(m)).toList();
    } catch (e) {
      LoggerService.error('Error getting debts', error: e);
      rethrow;
    }
  }

  /// Add debt
  Future<DebtModel> addDebt(Map<String, dynamic> debtData) async {
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
      return DebtModel.fromMap(data);
    } catch (e) {
      LoggerService.error('Error adding debt', error: e);
      rethrow;
    }
  }

  /// Record debt payment
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

  /// Get debt payments
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

  /// Get debt summary
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

  /// Delete debt
  Future<bool> deleteDebt(String debtId) async {
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
        return true;
      }
      return false;
    } catch (e) {
      LoggerService.error('Error deleting debt', error: e);
      rethrow;
    }
  }
}
