import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:financial_app/models/place_visit.dart';
import 'package:financial_app/models/transaction_model.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/location_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';

/// Data service for PlaceVisit CRUD operations.
///
/// Deduplicates places by (osm_node_id) or rough coordinate bounding,
/// and aggregates visit_count + total_spent across transactions.
class PlaceVisitDataService {
  final LocalDatabaseService _dbService;
  final LocalAuthService _authService;
  final _uuid = const Uuid();

  PlaceVisitDataService({
    LocalDatabaseService? dbService,
    LocalAuthService? authService,
  }) : _dbService = dbService ?? LocalDatabaseService(),
       _authService = authService ?? LocalAuthService();

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    return await _authService.getCurrentUserId();
  }

  /// Get all place visits, optionally filtered by category.
  Future<List<PlaceVisit>> getPlaceVisits({String? category}) async {
    try {
      final db = await _dbService.database;
      var where = '';
      var whereArgs = <dynamic>[];

      if (category != null && category.isNotEmpty) {
        where = 'category_232143 = ?';
        whereArgs = [category];
      }

      final rows = await db.query(
        'place_visits_232143',
        where: where.isEmpty ? null : where,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'last_visit_232143 DESC',
      );

      return rows.map((m) => PlaceVisit.fromMap(m)).toList();
    } catch (e) {
      LoggerService.error('Error getting place visits', error: e);
      rethrow;
    }
  }

  /// Get a single place visit by ID.
  Future<PlaceVisit?> getPlaceVisit(String id) async {
    try {
      final db = await _dbService.database;
      final rows = await db.query(
        'place_visits_232143',
        where: 'place_visit_id_232143 = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return PlaceVisit.fromMap(rows.first);
    } catch (e) {
      LoggerService.error('Error getting place visit', error: e);
      rethrow;
    }
  }

  /// Find an existing place visit by OSM node ID.
  Future<PlaceVisit?> findByOsmNodeId(String osmNodeId) async {
    try {
      final db = await _dbService.database;
      final rows = await db.query(
        'place_visits_232143',
        where: 'osm_node_id_232143 = ?',
        whereArgs: [osmNodeId],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return PlaceVisit.fromMap(rows.first);
    } catch (e) {
      LoggerService.error('Error finding place visit by OSM node', error: e);
      rethrow;
    }
  }

  /// Find existing place visit by approximate location (within ~100m of given coords).
  Future<PlaceVisit?> findByApproximateLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      final db = await _dbService.database;
      final rows = await db.query('place_visits_232143');
      if (rows.isEmpty) return null;

      const maxDistanceMeters = 100.0;
      PlaceVisit? closest;
      double closestDist = double.infinity;

      for (final row in rows) {
        final visit = PlaceVisit.fromMap(row);
        final dist = LocationService.calculateDistance(
          latitude,
          longitude,
          visit.latitude,
          visit.longitude,
        );
        if (dist < maxDistanceMeters && dist < closestDist) {
          closest = visit;
          closestDist = dist;
        }
      }
      return closest;
    } catch (e) {
      LoggerService.error(
        'Error finding place visit by approximate location',
        error: e,
      );
      rethrow;
    }
  }

  /// Upsert a place visit from a transaction's location data.
  /// Returns the (possibly existing) PlaceVisit.
  Future<PlaceVisit> upsertFromTransaction(TransactionModel transaction) async {
    try {
      final ldata = transaction.locationData;
      if (ldata == null) {
        throw Exception('Transaction has no location data');
      }

      final lat = (ldata['latitude'] as num?)?.toDouble() ?? 0.0;
      final lng = (ldata['longitude'] as num?)?.toDouble() ?? 0.0;
      final placeName =
          ldata['place_name']?.toString() ?? transaction.description;
      final osmNodeId = ldata['osm_node_id']?.toString();

      // Try to find existing visit by OSM node or approximate location
      PlaceVisit? existing;
      if (osmNodeId != null && osmNodeId.isNotEmpty) {
        existing = await findByOsmNodeId(osmNodeId);
      }
      if (existing == null) {
        existing = await findByApproximateLocation(lat, lng);
      }

      final now = DateTime.now();
      final txnDate = transaction.transactionDate;

      if (existing != null) {
        // Update existing
        final db = await _dbService.database;
        await db.update(
          'place_visits_232143',
          {
            'visit_count_232143': existing.visitCount + 1,
            'total_spent_232143': existing.totalSpent + transaction.amount,
            'last_visit_232143': txnDate.toIso8601String().split('T')[0],
          },
          where: 'place_visit_id_232143 = ?',
          whereArgs: [existing.id],
        );
        LoggerService.info(
          '✅ PlaceVisit updated: ${existing.placeName} '
          '(visits: ${existing.visitCount + 1})',
        );
        return PlaceVisit(
          id: existing.id,
          osmNodeId: existing.osmNodeId ?? osmNodeId,
          placeName: existing.placeName,
          latitude: existing.latitude,
          longitude: existing.longitude,
          address: existing.address ?? ldata['address']?.toString(),
          category: existing.category,
          osmTag: existing.osmTag,
          visitCount: existing.visitCount + 1,
          totalSpent: existing.totalSpent + transaction.amount,
          firstVisit: existing.firstVisit,
          lastVisit: txnDate,
          createdAt: existing.createdAt,
        );
      } else {
        // Create new
        final id = _uuid.v4();
        final category = transaction.categoryName;
        final db = await _dbService.database;

        await db.insert('place_visits_232143', {
          'place_visit_id_232143': id,
          'osm_node_id_232143': osmNodeId,
          'place_name_232143': placeName,
          'latitude_232143': lat,
          'longitude_232143': lng,
          'address_232143': ldata['address']?.toString(),
          'category_232143': category,
          'osm_tag_232143': ldata['osm_tag']?.toString(),
          'visit_count_232143': 1,
          'total_spent_232143': transaction.amount,
          'first_visit_232143': txnDate.toIso8601String().split('T')[0],
          'last_visit_232143': txnDate.toIso8601String().split('T')[0],
          'created_at_232143': now.toIso8601String(),
        });

        LoggerService.info('✅ PlaceVisit created: $placeName');
        return PlaceVisit(
          id: id,
          osmNodeId: osmNodeId,
          placeName: placeName,
          latitude: lat,
          longitude: lng,
          address: ldata['address']?.toString(),
          category: category,
          osmTag: ldata['osm_tag']?.toString(),
          visitCount: 1,
          totalSpent: transaction.amount,
          firstVisit: txnDate,
          lastVisit: txnDate,
          createdAt: now,
        );
      }
    } catch (e) {
      LoggerService.error(
        'Error upserting place visit from transaction',
        error: e,
      );
      rethrow;
    }
  }

  /// Scan all expense transactions with location data and create/update
  /// PlaceVisit records for each. Returns the number of visits synced.
  ///
  /// Idempotent — existing visits are updated (visit_count, total_spent)
  /// rather than duplicated. This is safe to call on every startup.
  Future<int> syncFromTransactions(TransactionDataService txnService) async {
    try {
      final data = await txnService.getTransactions(limit: 5000);
      final transactions = List<Map<String, dynamic>>.from(
        data['transactions'] ?? [],
      );

      LoggerService.info(
        'PlaceVisitSync: scanning ${transactions.length} transactions...',
      );

      int synced = 0;
      int skipped = 0;

      for (final txn in transactions) {
        final type = txn['type_232143']?.toString() ?? 'expense';
        final lat = (txn['latitude_232143'] as num?)?.toDouble();
        final lng = (txn['longitude_232143'] as num?)?.toDouble();
        final locationName = txn['location_name_232143']?.toString();

        // Skip non-expenses or transactions without location coordinates
        if (type != 'expense' || lat == null || lng == null) {
          skipped++;
          continue;
        }

        try {
          // If location_data_232143 is missing, synthesize it from the
          // separate latitude/longitude/location_name columns
          if (txn['location_data_232143'] == null) {
            txn['location_data_232143'] = json.encode({
              'latitude': lat,
              'longitude': lng,
              'place_name':
                  locationName ??
                  txn['description_232143']?.toString() ??
                  'Unknown Location',
              'address': locationName,
            });
          }

          final model = TransactionModel.fromMap(
            Map<String, dynamic>.from(txn),
          );

          if (model.locationData != null) {
            await upsertFromTransaction(model);
            synced++;
          } else {
            skipped++;
          }
        } catch (e) {
          LoggerService.error(
            'PlaceVisitSync: error syncing transaction ${txn['transaction_id_232143']}',
            error: e,
          );
          skipped++;
        }
      }

      LoggerService.info(
        'PlaceVisitSync: done — $synced synced, $skipped skipped',
      );
      return synced;
    } catch (e) {
      LoggerService.error('PlaceVisitSync: sync failed', error: e);
      rethrow;
    }
  }

  /// Delete a place visit.
  Future<bool> deletePlaceVisit(String id) async {
    try {
      final db = await _dbService.database;
      final rowsDeleted = await db.delete(
        'place_visits_232143',
        where: 'place_visit_id_232143 = ?',
        whereArgs: [id],
      );
      if (rowsDeleted > 0) {
        LoggerService.info('✅ PlaceVisit deleted: $id');
        return true;
      }
      return false;
    } catch (e) {
      LoggerService.error('Error deleting place visit', error: e);
      rethrow;
    }
  }
}
