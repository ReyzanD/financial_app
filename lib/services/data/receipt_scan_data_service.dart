import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/logger_service.dart';

/// Data service for Receipt Scan CRUD operations.
class ReceiptScanDataService {
  final LocalDatabaseService _dbService;
  final LocalAuthService _authService;
  final _uuid = const Uuid();

  ReceiptScanDataService({
    LocalDatabaseService? dbService,
    LocalAuthService? authService,
  }) : _dbService = dbService ?? LocalDatabaseService(),
       _authService = authService ?? LocalAuthService();

  Future<String?> getCurrentUserId() async =>
      _authService.getCurrentUserId();

  /// Save a receipt scan record
  Future<Map<String, dynamic>> saveReceiptScan(
    Map<String, dynamic> receiptData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final receiptId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final itemsJson =
          receiptData['items'] != null
              ? jsonEncode(receiptData['items'])
              : null;

      final data = {
        'receipt_id_232143': receiptId,
        'user_id_232143': userId,
        'image_path_232143': receiptData['image_path'],
        'merchant_232143': receiptData['merchant'],
        'total_amount_232143': receiptData['total_amount'] ?? 0.0,
        'receipt_date_232143': receiptData['receipt_date'],
        'raw_text_232143': receiptData['raw_text'],
        'items_json_232143': itemsJson,
        'category_id_232143': receiptData['category_id'],
        'transaction_id_232143': receiptData['transaction_id'],
        'is_processed_232143': receiptData['is_processed'] ?? 0,
        'confidence_score_232143': receiptData['confidence'] ?? 0.0,
        'created_at_232143': now,
        'updated_at_232143': now,
      };

      await db.insert('receipt_scans_232143', data);
      LoggerService.info('✅ Receipt scan saved: $receiptId');
      return {'receipt': data};
    } catch (e) {
      LoggerService.error('Error saving receipt scan', error: e);
      rethrow;
    }
  }

  /// Get all receipt scans
  Future<List<Map<String, dynamic>>> getReceiptScans({
    int limit = 50,
    int offset = 0,
    bool? processedOnly,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      var where = 'user_id_232143 = ?';
      var whereArgs = <dynamic>[userId];

      if (processedOnly != null) {
        where += ' AND is_processed_232143 = ?';
        whereArgs.add(processedOnly ? 1 : 0);
      }

      final scans = await db.query(
        'receipt_scans_232143',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'created_at_232143 DESC',
        limit: limit,
        offset: offset,
      );

      final scansWithItems =
          scans.map<Map<String, dynamic>>((scan) {
            final scanMap = Map<String, dynamic>.from(scan);
            final itemsJson = scanMap['items_json_232143'] as String?;
            if (itemsJson != null) {
              try {
                scanMap['items'] = jsonDecode(itemsJson);
              } catch (e) {
                scanMap['items'] = [];
              }
            } else {
              scanMap['items'] = [];
            }
            return scanMap;
          }).toList();

      return scansWithItems;
    } catch (e) {
      LoggerService.error('Error getting receipt scans', error: e);
      rethrow;
    }
  }

  /// Get a single receipt scan
  Future<Map<String, dynamic>?> getReceiptScan(String receiptId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final scans = await db.query(
        'receipt_scans_232143',
        where: 'receipt_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [receiptId, userId],
        limit: 1,
      );

      if (scans.isEmpty) return null;

      final scan = Map<String, dynamic>.from(scans.first);
      final itemsJson = scan['items_json_232143'] as String?;
      if (itemsJson != null) {
        try {
          scan['items'] = jsonDecode(itemsJson);
        } catch (e) {
          scan['items'] = [];
        }
      } else {
        scan['items'] = [];
      }
      return scan;
    } catch (e) {
      LoggerService.error('Error getting receipt scan', error: e);
      rethrow;
    }
  }

  /// Delete a receipt scan
  Future<Map<String, dynamic>> deleteReceiptScan(String receiptId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final scan = await db.query(
        'receipt_scans_232143',
        where: 'receipt_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [receiptId, userId],
        limit: 1,
      );

      if (scan.isEmpty) {
        return {'success': false, 'message': 'Receipt not found'};
      }

      final rowsDeleted = await db.delete(
        'receipt_scans_232143',
        where: 'receipt_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [receiptId, userId],
      );

      if (rowsDeleted > 0) {
        LoggerService.info('✅ Receipt scan deleted: $receiptId');
        return {'success': true, 'message': 'Receipt deleted successfully'};
      } else {
        return {'success': false, 'message': 'Receipt not found'};
      }
    } catch (e) {
      LoggerService.error('Error deleting receipt scan', error: e);
      rethrow;
    }
  }

  /// Update receipt scan linked transaction
  Future<Map<String, dynamic>> linkReceiptToTransaction(
    String receiptId,
    String transactionId,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final now = DateTime.now().toIso8601String();

      final rowsUpdated = await db.update(
        'receipt_scans_232143',
        {
          'transaction_id_232143': transactionId,
          'is_processed_232143': 1,
          'updated_at_232143': now,
        },
        where: 'receipt_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [receiptId, userId],
      );

      if (rowsUpdated > 0) {
        LoggerService.info(
          '✅ Receipt linked to transaction: $receiptId -> $transactionId',
        );
        return {'success': true, 'message': 'Receipt linked successfully'};
      } else {
        return {'success': false, 'message': 'Receipt not found'};
      }
    } catch (e) {
      LoggerService.error('Error linking receipt to transaction', error: e);
      rethrow;
    }
  }
}
