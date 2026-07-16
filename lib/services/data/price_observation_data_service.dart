import 'package:uuid/uuid.dart';
import 'package:financial_app/models/price_observation.dart';
import 'package:financial_app/models/transaction_model.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/logger_service.dart';

/// Data service for PriceObservation CRUD and aggregation operations.
class PriceObservationDataService {
  final LocalDatabaseService _dbService;
  final LocalAuthService _authService;
  final _uuid = const Uuid();

  PriceObservationDataService({
    LocalDatabaseService? dbService,
    LocalAuthService? authService,
  }) : _dbService = dbService ?? LocalDatabaseService(),
       _authService = authService ?? LocalAuthService();

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    return await _authService.getCurrentUserId();
  }

  /// Get all price observations, optionally filtered.
  Future<List<PriceObservation>> getPriceObservations({
    String? placeVisitId,
    String? category,
  }) async {
    try {
      final db = await _dbService.database;
      var conditions = <String>[];
      var args = <dynamic>[];

      if (placeVisitId != null) {
        conditions.add('place_visit_id_232143 = ?');
        args.add(placeVisitId);
      }
      if (category != null) {
        conditions.add('category_232143 = ?');
        args.add(category);
      }

      final where = conditions.isNotEmpty ? conditions.join(' AND ') : null;

      final rows = await db.query(
        'price_observations_232143',
        where: where,
        whereArgs: args.isNotEmpty ? args : null,
        orderBy: 'observed_at_232143 DESC',
      );

      return rows.map((m) => PriceObservation.fromMap(m)).toList();
    } catch (e) {
      LoggerService.error('Error getting price observations', error: e);
      rethrow;
    }
  }

  /// Create a price observation, typically from a transaction + place visit.
  Future<PriceObservation> createFromTransaction({
    required String placeVisitId,
    required TransactionModel transaction,
    String source = 'auto_extracted',
  }) async {
    try {
      final id = _uuid.v4();
      final now = DateTime.now();
      final db = await _dbService.database;

      await db.insert('price_observations_232143', {
        'price_observation_id_232143': id,
        'place_visit_id_232143': placeVisitId,
        'category_232143': transaction.categoryName,
        'price_232143': transaction.amount,
        'currency_232143': 'IDR',
        'observed_at_232143':
            transaction.transactionDate.toIso8601String().split('T')[0],
        'source_232143': source,
        'transaction_id_232143': transaction.id,
        'created_at_232143': now.toIso8601String(),
      });

      LoggerService.info('✅ PriceObservation created: $id');
      return PriceObservation(
        id: id,
        placeVisitId: placeVisitId,
        category: transaction.categoryName,
        price: transaction.amount,
        currency: 'IDR',
        observedAt: transaction.transactionDate,
        source: source,
        transactionId: transaction.id,
        createdAt: now,
      );
    } catch (e) {
      LoggerService.error(
        'Error creating price observation from transaction',
        error: e,
      );
      rethrow;
    }
  }

  /// Get median price for a category across all places, excluding outliers.
  ///
  /// Returns null if fewer than [minObservations] data points exist.
  Future<double?> getMedianPriceForCategory(
    String category, {
    int minObservations = 3,
  }) async {
    try {
      final db = await _dbService.database;
      final rows = await db.rawQuery(
        '''
        SELECT price_232143 FROM price_observations_232143
        WHERE category_232143 = ?
        ORDER BY price_232143 ASC
        ''',
        [category],
      );

      if (rows.length < minObservations) return null;

      final prices =
          rows.map((r) => (r['price_232143'] as num).toDouble()).toList();

      // Remove top/bottom 10% as outlier trim
      final trimCount = (prices.length * 0.1).floor();
      final trimmed = prices.sublist(trimCount, prices.length - trimCount);
      if (trimmed.isEmpty) return prices[prices.length ~/ 2];

      // Median of trimmed set
      final mid = trimmed.length ~/ 2;
      if (trimmed.length.isEven) {
        return (trimmed[mid - 1] + trimmed[mid]) / 2;
      }
      return trimmed[mid];
    } catch (e) {
      LoggerService.error(
        'Error computing median price for category',
        error: e,
      );
      rethrow;
    }
  }

  /// Get the lowest price for a category across all visited places.
  /// Returns null if no observations exist.
  Future<PriceObservation?> getCheapestForCategory(String category) async {
    try {
      final db = await _dbService.database;
      final rows = await db.rawQuery(
        '''
        SELECT * FROM price_observations_232143
        WHERE category_232143 = ?
        ORDER BY price_232143 ASC
        LIMIT 1
        ''',
        [category],
      );
      if (rows.isEmpty) return null;
      return PriceObservation.fromMap(rows.first);
    } catch (e) {
      LoggerService.error(
        'Error finding cheapest price for category',
        error: e,
      );
      rethrow;
    }
  }

  /// Get all price observations for a specific place visit.
  Future<List<PriceObservation>> getForPlaceVisit(String placeVisitId) async {
    return getPriceObservations(placeVisitId: placeVisitId);
  }

  /// Delete a price observation.
  Future<bool> deletePriceObservation(String id) async {
    try {
      final db = await _dbService.database;
      final rowsDeleted = await db.delete(
        'price_observations_232143',
        where: 'price_observation_id_232143 = ?',
        whereArgs: [id],
      );
      if (rowsDeleted > 0) {
        LoggerService.info('✅ PriceObservation deleted: $id');
        return true;
      }
      return false;
    } catch (e) {
      LoggerService.error('Error deleting price observation', error: e);
      rethrow;
    }
  }
}
