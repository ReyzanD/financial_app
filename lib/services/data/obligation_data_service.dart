import 'package:uuid/uuid.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/logger_service.dart';

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
  Future<List<Map<String, dynamic>>> getObligations({String? type}) async {
    try {
      final userId = await getCurrentUserId();
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
      final userId = await getCurrentUserId();
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
