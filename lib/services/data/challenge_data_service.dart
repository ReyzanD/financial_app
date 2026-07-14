import 'package:uuid/uuid.dart';
import 'package:financial_app/models/challenge_model.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/logger_service.dart';

/// Data service for Challenge CRUD operations.
class ChallengeDataService {
  final LocalDatabaseService _dbService;
  final LocalAuthService _authService;
  final _uuid = const Uuid();

  ChallengeDataService({
    LocalDatabaseService? dbService,
    LocalAuthService? authService,
  }) : _dbService = dbService ?? LocalDatabaseService(),
       _authService = authService ?? LocalAuthService();

  Future<String?> getCurrentUserId() async => _authService.getCurrentUserId();

  Future<List<ChallengeModel>> getChallenges({
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

      final challenges = await db.query(
        'challenges_232143',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'end_date_232143 ASC',
      );
      return challenges.map((m) => ChallengeModel.fromMap(m)).toList();
    } catch (e) {
      LoggerService.error('Error getting challenges', error: e);
      rethrow;
    }
  }

  Future<ChallengeModel> addChallenge(
    Map<String, dynamic> challengeData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final challengeId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final data = {
        'challenge_id_232143': challengeId,
        'user_id_232143': userId,
        'name_232143': challengeData['name'],
        'description_232143': challengeData['description'],
        'type_232143': challengeData['type'] ?? 'custom',
        'target_amount_232143': challengeData['target_amount'],
        'current_amount_232143': challengeData['current_amount'] ?? 0.0,
        'start_date_232143': challengeData['start_date'] ?? now.split('T')[0],
        'end_date_232143': challengeData['end_date'],
        'is_active_232143': challengeData['is_active'] != false ? 1 : 0,
        'streak_days_232143': challengeData['streak_days'] ?? 0,
        'notes_232143': challengeData['notes'],
        'created_at_232143': now,
        'updated_at_232143': now,
      };

      await db.insert('challenges_232143', data);
      LoggerService.info('✅ Challenge added: $challengeId');
      return ChallengeModel.fromMap(data);
    } catch (e) {
      LoggerService.error('Error adding challenge', error: e);
      rethrow;
    }
  }

  Future<void> updateChallenge(
    String challengeId,
    Map<String, dynamic> challengeData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final now = DateTime.now().toIso8601String();

      final updateData = <String, dynamic>{'updated_at_232143': now};

      if (challengeData.containsKey('name')) {
        updateData['name_232143'] = challengeData['name'];
      }
      if (challengeData.containsKey('description')) {
        updateData['description_232143'] = challengeData['description'];
      }
      if (challengeData.containsKey('target_amount')) {
        updateData['target_amount_232143'] = challengeData['target_amount'];
      }
      if (challengeData.containsKey('current_amount')) {
        updateData['current_amount_232143'] = challengeData['current_amount'];
      }
      if (challengeData.containsKey('is_active')) {
        updateData['is_active_232143'] = challengeData['is_active'] ? 1 : 0;
      }
      if (challengeData.containsKey('is_completed')) {
        updateData['is_completed_232143'] =
            challengeData['is_completed'] ? 1 : 0;
        if (challengeData['is_completed'] == true) {
          updateData['completed_date_232143'] = now.split('T')[0];
        }
      }
      if (challengeData.containsKey('streak_days')) {
        updateData['streak_days_232143'] = challengeData['streak_days'];
      }

      await db.update(
        'challenges_232143',
        updateData,
        where: 'challenge_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [challengeId, userId],
      );

      LoggerService.info('✅ Challenge updated: $challengeId');
    } catch (e) {
      LoggerService.error('Error updating challenge', error: e);
      rethrow;
    }
  }

  Future<bool> deleteChallenge(String challengeId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final rowsDeleted = await db.delete(
        'challenges_232143',
        where: 'challenge_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [challengeId, userId],
      );

      if (rowsDeleted > 0) {
        LoggerService.info('✅ Challenge deleted: $challengeId');
      }
      return rowsDeleted > 0;
    } catch (e) {
      LoggerService.error('Error deleting challenge', error: e);
      rethrow;
    }
  }
}
