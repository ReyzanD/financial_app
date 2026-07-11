import 'package:flutter/foundation.dart';

/// Centralized logging service
/// - Debug logs only in debug mode
/// - Structured logging with levels
/// - Easy to disable/enable
class LoggerService {
  static const bool _enableLogging = kDebugMode;
  static const bool _enableVerboseLogging = kDebugMode;

  /// Log debug messages (only in debug mode)
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    if (!_enableLogging) return;
    if (_enableVerboseLogging) {
      debugPrint('🐛 [DEBUG] $message');
      if (error != null) debugPrint('   Error: $error');
      if (stackTrace != null) debugPrint('   Stack: $stackTrace');
    }
  }

  /// Log info messages
  static void info(String message) {
    if (!_enableLogging) return;
    debugPrint('ℹ️ [INFO] $message');
  }

  /// Log success messages
  static void success(String message) {
    if (!_enableLogging) return;
    debugPrint('✅ [SUCCESS] $message');
  }

  /// Log warning messages
  static void warning(String message, {Object? error}) {
    if (!_enableLogging) return;
    debugPrint('⚠️ [WARNING] $message');
    if (error != null) debugPrint('   Error: $error');
  }

  /// Log error messages
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (!_enableLogging) return;
    debugPrint('❌ [ERROR] $message');
    if (error != null) debugPrint('   Error: $error');
    if (stackTrace != null && _enableVerboseLogging) {
      debugPrint('   Stack: $stackTrace');
    }
  }

  /// Log API requests
  static void apiRequest(String method, String endpoint) {
    if (!_enableLogging) return;
    debugPrint('📡 [API] $method $endpoint');
  }

  /// Log API responses
  static void apiResponse(int statusCode, String endpoint) {
    if (!_enableLogging) return;
    if (statusCode >= 200 && statusCode < 300) {
      debugPrint('✅ [API] $statusCode $endpoint');
    } else if (statusCode == 404) {
      // 404 is logged as debug, not error (endpoint might not exist yet)
      debug('API 404: $endpoint');
    } else {
      debugPrint('❌ [API] $statusCode $endpoint');
    }
  }

  /// Log cache operations
  static void cache(String operation, String key) {
    if (!_enableLogging) return;
    debugPrint('📦 [CACHE] $operation: $key');
  }
}
