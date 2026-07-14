import 'package:uuid/uuid.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/models/split_model.dart';

/// Data service for Expense Split CRUD operations.
class ExpenseSplitDataService {
  final LocalDatabaseService _dbService;
  final LocalAuthService _authService;
  final _uuid = const Uuid();

  ExpenseSplitDataService({
    LocalDatabaseService? dbService,
    LocalAuthService? authService,
  }) : _dbService = dbService ?? LocalDatabaseService(),
       _authService = authService ?? LocalAuthService();

  Future<String?> getCurrentUserId() async => _authService.getCurrentUserId();

  Future<List<SplitModel>> getSplits({
    String? transactionId,
    bool activeOnly = true,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      var where = 'user_id_232143 = ?';
      var whereArgs = <dynamic>[userId];

      if (transactionId != null) {
        where += ' AND transaction_id_232143 = ?';
        whereArgs.add(transactionId);
      }
      if (activeOnly) {
        where += ' AND is_settled_232143 = 0';
      }

      final splits = await db.query(
        'expense_splits_232143',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'created_at_232143 DESC',
      );
      return splits.map((m) => SplitModel.fromMap(m)).toList();
    } catch (e) {
      LoggerService.error('Error getting splits', error: e);
      rethrow;
    }
  }

  Future<SplitModel> addSplit(Map<String, dynamic> splitData) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final splitId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final record = <String, dynamic>{
        'split_id_232143': splitId,
        'transaction_id_232143': splitData['transaction_id'],
        'user_id_232143': userId,
        'participant_name_232143': splitData['participant_name'],
        'participant_phone_232143': splitData['participant_phone'],
        'amount_232143': splitData['amount'],
        'paid_amount_232143': splitData['paid_amount'] ?? 0.0,
        'is_settled_232143': splitData['is_settled'] == true ? 1 : 0,
        'notes_232143': splitData['notes'],
        'created_at_232143': now,
      };

      await db.insert('expense_splits_232143', record);

      LoggerService.info('✅ Split added: $splitId');
      return SplitModel.fromMap(record);
    } catch (e) {
      LoggerService.error('Error adding split', error: e);
      rethrow;
    }
  }

  Future<void> settleSplit(String splitId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final now = DateTime.now().toIso8601String();

      await db.update(
        'expense_splits_232143',
        {'is_settled_232143': 1, 'settled_at_232143': now},
        where: 'split_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [splitId, userId],
      );

      LoggerService.info('✅ Split settled: $splitId');
    } catch (e) {
      LoggerService.error('Error settling split', error: e);
      rethrow;
    }
  }

  Future<bool> deleteSplit(String splitId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final rowsDeleted = await db.delete(
        'expense_splits_232143',
        where: 'split_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [splitId, userId],
      );

      if (rowsDeleted > 0) {
        LoggerService.info('✅ Split deleted: $splitId');
      }
      return rowsDeleted > 0;
    } catch (e) {
      LoggerService.error('Error deleting split', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSplitSummary() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final result = await db.rawQuery(
        '''
        SELECT
          SUM(CASE WHEN is_settled_232143 = 0 THEN (amount_232143 - paid_amount_232143) ELSE 0 END) as total_owed,
          SUM(CASE WHEN is_settled_232143 = 1 THEN amount_232143 ELSE 0 END) as total_settled,
          SUM(CASE WHEN is_settled_232143 = 0 THEN 1 ELSE 0 END) as active_count,
          SUM(CASE WHEN is_settled_232143 = 1 THEN 1 ELSE 0 END) as settled_count
        FROM expense_splits_232143
        WHERE user_id_232143 = ?
      ''',
        [userId],
      );

      final row = result.first;
      return {
        'total_owed': (row['total_owed'] as num?)?.toDouble() ?? 0.0,
        'total_settled': (row['total_settled'] as num?)?.toDouble() ?? 0.0,
        'active_count': (row['active_count'] as int?) ?? 0,
        'settled_count': (row['settled_count'] as int?) ?? 0,
      };
    } catch (e) {
      LoggerService.error('Error getting split summary', error: e);
      rethrow;
    }
  }
}
