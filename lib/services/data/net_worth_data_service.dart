import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/logger_service.dart';

/// Data service for Net Worth history CRUD operations.
class NetWorthDataService {
  final LocalDatabaseService _dbService;
  final LocalAuthService _authService;
  final _uuid = const Uuid();

  NetWorthDataService({LocalDatabaseService? dbService, LocalAuthService? authService})
    : _dbService = dbService ?? LocalDatabaseService(),
      _authService = authService ?? LocalAuthService();

  Future<String?> getCurrentUserId() async => _authService.getCurrentUserId();

  Future<Map<String, dynamic>> recordNetWorthSnapshot(Map<String, dynamic> snapshotData) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final snapshotId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      await db.insert('net_worth_history_232143', {
        'snapshot_id_232143': snapshotId,
        'user_id_232143': userId,
        'snapshot_date_232143': snapshotData['snapshot_date'] ?? now.split('T')[0],
        'net_worth_232143': snapshotData['net_worth'],
        'total_assets_232143': snapshotData['total_assets'],
        'total_liabilities_232143': snapshotData['total_liabilities'],
        'asset_breakdown_232143':
            snapshotData['asset_breakdown'] != null ? json.encode(snapshotData['asset_breakdown']) : null,
        'liability_breakdown_232143':
            snapshotData['liability_breakdown'] != null ? json.encode(snapshotData['liability_breakdown']) : null,
        'created_at_232143': now,
      });

      LoggerService.info('✅ Net worth snapshot recorded: $snapshotId');
      return {'success': true, 'snapshot_id': snapshotId};
    } catch (e) {
      LoggerService.error('Error recording net worth snapshot', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getNetWorthHistory({int limit = 90}) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final snapshots = await db.query(
        'net_worth_history_232143',
        where: 'user_id_232143 = ?',
        whereArgs: [userId],
        orderBy: 'snapshot_date_232143 DESC',
        limit: limit,
      );

      return List<Map<String, dynamic>>.from(snapshots).map((s) {
        final map = Map<String, dynamic>.from(s);
        final assetBreakdown = map['asset_breakdown_232143'] as String?;
        final liabilityBreakdown = map['liability_breakdown_232143'] as String?;

        if (assetBreakdown != null) {
          try {
            map['asset_breakdown'] = json.decode(assetBreakdown);
          } catch (e) {
            map['asset_breakdown'] = {};
          }
        }
        if (liabilityBreakdown != null) {
          try {
            map['liability_breakdown'] = json.decode(liabilityBreakdown);
          } catch (e) {
            map['liability_breakdown'] = {};
          }
        }
        return map;
      }).toList();
    } catch (e) {
      LoggerService.error('Error getting net worth history', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getNetWorthTrend() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final result = await db.rawQuery(
        '''
        SELECT net_worth_232143, snapshot_date_232143
        FROM net_worth_history_232143
        WHERE user_id_232143 = ?
        ORDER BY snapshot_date_232143 ASC
      ''',
        [userId],
      );

      if (result.isEmpty) {
        return {'trend': 'no_data', 'change': 0.0};
      }

      final first = (result.first['net_worth_232143'] as num?)?.toDouble() ?? 0.0;
      final last = (result.last['net_worth_232143'] as num?)?.toDouble() ?? 0.0;
      final change = first != 0 ? ((last - first) / first.abs()) * 100 : 0.0;

      return {
        'trend':
            change > 0
                ? 'increasing'
                : change < 0
                ? 'decreasing'
                : 'stable',
        'change_percent': change,
        'start_value': first,
        'end_value': last,
        'data_points': result.length,
      };
    } catch (e) {
      LoggerService.error('Error getting net worth trend', error: e);
      rethrow;
    }
  }
}
