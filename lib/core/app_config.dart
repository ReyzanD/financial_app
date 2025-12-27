import 'package:financial_app/services/logger_service.dart';

/// Centralized application configuration
///
/// **STANDALONE MODE - NO BACKEND SERVER REQUIRED**
/// This app now runs fully standalone with local SQLite database.
/// No backend server, no API URLs, no network calls needed.
/// All data is stored locally on the device.
class AppConfig {
  static bool _initialized = false;

  /// Initialize AppConfig
  /// Call this once at app startup (in main.dart)
  static Future<void> initialize() async {
    if (_initialized) return;
    
    LoggerService.info('📱 App running in standalone mode (no backend required)');
    _initialized = true;
  }

  /// Determine if we're in production mode
  ///
  /// Always returns false for standalone mode.
  static bool get isProduction {
    return false;
  }

  /// Get the base URL for API calls
  ///
  /// Not used in standalone mode - returns empty string
  @Deprecated('Not needed in standalone mode')
  static String get baseUrl {
    return '';
  }

  /// Get the auth endpoint base URL
  ///
  /// Not used in standalone mode - returns empty string
  @Deprecated('Not needed in standalone mode')
  static String get authBaseUrl {
    return '';
  }

  /// Get the effective base URL
  ///
  /// Not used in standalone mode - returns empty string
  @Deprecated('Not needed in standalone mode')
  static String get effectiveBaseUrl {
    return '';
  }

  /// Get the effective auth base URL
  ///
  /// Not used in standalone mode - returns empty string
  @Deprecated('Not needed in standalone mode')
  static String get effectiveAuthBaseUrl {
    return '';
  }
}
