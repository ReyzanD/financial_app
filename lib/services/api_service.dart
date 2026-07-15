import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:financial_app/services/logger_service.dart';

/// API Service - Legacy facade for data operations
///
/// All services have been migrated to typed data services
/// (TransactionDataService, BudgetDataService, etc.).
/// This class is retained only for:
///   - `clearCache()` static method (called by auth_service.dart on logout)
///   - `getHeaders()` for any remaining HTTP-header consumers
class ApiService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService();

  /// Get auth headers for HTTP calls
  Future<Map<String, String>> getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ===================================================================
  // Static cache layer
  // ===================================================================
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};

  /// Clear all or specific cached data
  static void clearCache([String? key]) {
    if (key != null) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
    }
    LoggerService.debug('[ApiService] Cache cleared${key != null ? " for key: $key" : ""}');
  }
}
