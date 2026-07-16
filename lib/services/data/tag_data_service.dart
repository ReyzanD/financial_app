import 'package:uuid/uuid.dart';
import 'package:financial_app/models/transaction_tag_model.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/logger_service.dart';

/// Data service for Tag CRUD operations.
/// Extracted from the monolithic LocalDataService facade.
class TagDataService {
  final LocalDatabaseService _dbService;
  final LocalAuthService _authService;
  final _uuid = const Uuid();

  TagDataService({LocalDatabaseService? dbService, LocalAuthService? authService})
    : _dbService = dbService ?? LocalDatabaseService(),
      _authService = authService ?? LocalAuthService();

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    return await _authService.getCurrentUserId();
  }

  /// Get all tags
  Future<List<TransactionTagModel>> getTags() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final tags = await db.query(
        'tags_232143',
        where: 'user_id_232143 = ?',
        whereArgs: [userId],
        orderBy: 'name_232143 ASC',
      );

      return tags.map((m) => TransactionTagModel.fromMap(m)).toList();
    } catch (e) {
      LoggerService.error('Error getting tags', error: e);
      rethrow;
    }
  }

  /// Add a tag
  Future<TransactionTagModel> addTag(String name, {String color = '#8B5FBF'}) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final tagId = _uuid.v4();
      final now = DateTime.now();

      await db.insert('tags_232143', {
        'tag_id_232143': tagId,
        'user_id_232143': userId,
        'name_232143': name,
        'color_232143': color,
        'created_at_232143': now.toIso8601String(),
      });

      LoggerService.info('✅ Tag added: $tagId');
      return TransactionTagModel(id: tagId, name: name, color: color, createdAt: now);
    } catch (e) {
      LoggerService.error('Error adding tag', error: e);
      rethrow;
    }
  }

  /// Delete a tag
  Future<bool> deleteTag(String tagId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final rowsDeleted = await db.delete(
        'tags_232143',
        where: 'tag_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [tagId, userId],
      );

      if (rowsDeleted > 0) {
        LoggerService.info('✅ Tag deleted: $tagId');
        return true;
      }
      return false;
    } catch (e) {
      LoggerService.error('Error deleting tag', error: e);
      rethrow;
    }
  }

  /// Get tags for a specific transaction
  Future<List<TransactionTagModel>> getTransactionTags(String transactionId) async {
    try {
      final db = await _dbService.database;
      final result = await db.rawQuery(
        '''
        SELECT t.* FROM tags_232143 t
        INNER JOIN transaction_tags_232143 tt ON t.tag_id_232143 = tt.tag_id_232143
        WHERE tt.transaction_id_232143 = ?
        ''',
        [transactionId],
      );

      return result.map((m) => TransactionTagModel.fromMap(m)).toList();
    } catch (e) {
      LoggerService.error('Error getting transaction tags', error: e);
      rethrow;
    }
  }

  /// Add a tag to a transaction
  Future<void> addTransactionTag(String transactionId, String tagId) async {
    try {
      final db = await _dbService.database;
      await db.insert('transaction_tags_232143', {'transaction_id_232143': transactionId, 'tag_id_232143': tagId});
    } catch (e) {
      LoggerService.error('Error adding transaction tag', error: e);
      rethrow;
    }
  }

  /// Remove a tag from a transaction
  Future<void> removeTransactionTag(String transactionId, String tagId) async {
    try {
      final db = await _dbService.database;
      await db.delete(
        'transaction_tags_232143',
        where: 'transaction_id_232143 = ? AND tag_id_232143 = ?',
        whereArgs: [transactionId, tagId],
      );
    } catch (e) {
      LoggerService.error('Error removing transaction tag', error: e);
      rethrow;
    }
  }
}
