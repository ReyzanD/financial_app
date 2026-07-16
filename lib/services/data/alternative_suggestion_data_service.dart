import 'package:financial_app/models/alternative_suggestion.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/logger_service.dart';

/// Data service for AlternativeSuggestion CRUD operations.
///
/// Persists the output of the Overpass + price-ranking engine so
/// results can be served offline after the first query.
class AlternativeSuggestionDataService {
  final LocalDatabaseService _dbService;
  final LocalAuthService _authService;

  AlternativeSuggestionDataService({
    LocalDatabaseService? dbService,
    LocalAuthService? authService,
  }) : _dbService = dbService ?? LocalDatabaseService(),
       _authService = authService ?? LocalAuthService();

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    return await _authService.getCurrentUserId();
  }

  /// Get cached suggestions for a given origin place visit.
  Future<List<AlternativeSuggestion>> getForOriginPlace(
    String originPlaceVisitId,
  ) async {
    try {
      final db = await _dbService.database;
      final rows = await db.query(
        'alternative_suggestions_232143',
        where: 'origin_place_visit_id_232143 = ?',
        whereArgs: [originPlaceVisitId],
        orderBy: 'confidence_level_232143 DESC, distance_meters_232143 ASC',
      );
      return rows.map((m) => AlternativeSuggestion.fromMap(m)).toList();
    } catch (e) {
      LoggerService.error(
        'Error getting suggestions for origin place',
        error: e,
      );
      rethrow;
    }
  }

  /// Save a batch of suggestions (replaces existing for the same origin).
  Future<void> saveSuggestions(List<AlternativeSuggestion> suggestions) async {
    try {
      if (suggestions.isEmpty) return;

      final db = await _dbService.database;
      final originId = suggestions.first.originPlaceVisitId;

      // Delete stale suggestions for this origin
      await db.delete(
        'alternative_suggestions_232143',
        where: 'origin_place_visit_id_232143 = ?',
        whereArgs: [originId],
      );

      // Insert new batch
      final batch = db.batch();
      for (final s in suggestions) {
        batch.insert('alternative_suggestions_232143', {
          'alternative_suggestion_id_232143': s.id,
          'origin_place_visit_id_232143': s.originPlaceVisitId,
          'suggested_place_name_232143': s.suggestedPlaceName,
          'suggested_osm_node_id_232143': s.suggestedOsmNodeId,
          'suggested_latitude_232143': s.suggestedLatitude,
          'suggested_longitude_232143': s.suggestedLongitude,
          'distance_meters_232143': s.distanceMeters,
          'estimated_savings_232143': s.estimatedSavings,
          'basis_232143': s.basis,
          'category_232143': s.category,
          'confidence_level_232143': s.confidenceLevel,
          'observation_count_232143': s.observationCount,
          'generated_at_232143': s.generatedAt.toIso8601String(),
          'created_at_232143': s.createdAt.toIso8601String(),
        });
      }
      await batch.commit(noResult: true);
      LoggerService.info(
        '✅ ${suggestions.length} alternative suggestions saved for origin $originId',
      );
    } catch (e) {
      LoggerService.error('Error saving alternative suggestions', error: e);
      rethrow;
    }
  }

  /// Check if fresh suggestions exist for a given origin (within [maxAgeHours]).
  Future<bool> hasFreshSuggestions(
    String originPlaceVisitId, {
    int maxAgeHours = 24,
  }) async {
    try {
      final db = await _dbService.database;
      final cutoff =
          DateTime.now()
              .subtract(Duration(hours: maxAgeHours))
              .toIso8601String();

      final result = await db.rawQuery(
        '''
        SELECT COUNT(*) as cnt FROM alternative_suggestions_232143
        WHERE origin_place_visit_id_232143 = ?
          AND generated_at_232143 >= ?
        ''',
        [originPlaceVisitId, cutoff],
      );

      final count = result.first['cnt'] as int;
      return count > 0;
    } catch (e) {
      LoggerService.error('Error checking fresh suggestions', error: e);
      return false;
    }
  }

  /// Delete all cached suggestions for an origin.
  Future<bool> deleteForOrigin(String originPlaceVisitId) async {
    try {
      final db = await _dbService.database;
      final deleted = await db.delete(
        'alternative_suggestions_232143',
        where: 'origin_place_visit_id_232143 = ?',
        whereArgs: [originPlaceVisitId],
      );
      if (deleted > 0) {
        LoggerService.info(
          '✅ Deleted $deleted suggestions for origin $originPlaceVisitId',
        );
        return true;
      }
      return false;
    } catch (e) {
      LoggerService.error('Error deleting suggestions for origin', error: e);
      rethrow;
    }
  }
}
