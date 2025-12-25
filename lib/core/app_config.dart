/// Centralized application configuration
///
/// This file manages environment-specific settings like API base URLs.
///
/// **LOCAL MODE CONFIGURATION**
/// This branch is configured for fully local deployment with SQLite database.
/// All API calls go to local backend (localhost:5000) - no Render/Supabase dependency.
///
/// For physical device testing, use setCustomBaseUrl() with your computer's IP address.
class AppConfig {
  // Local API URL (for Android emulator)
  // This is the default URL for local development with SQLite
  static const String _devBaseUrl = 'http://10.0.2.2:5000/api/v1';

  /// Determine if we're in production mode
  ///
  /// Always returns false for local mode deployment.
  static bool get isProduction {
    // Local mode - always return false
    return false;
  }

  /// Get the base URL for API calls
  ///
  /// Always returns local backend URL for this branch.
  /// Use setCustomBaseUrl() for physical device testing.
  static String get baseUrl {
    // Always use local URL for this branch
    return _devBaseUrl;
  }

  /// Get the auth endpoint base URL
  ///
  /// Convenience method for auth-related endpoints.
  static String get authBaseUrl => '$baseUrl/auth';

  /// Update production URL programmatically
  ///
  /// This can be used if you need to change the URL at runtime.
  /// Note: This requires storing the URL in shared preferences or similar.
  static String? _customBaseUrl;

  /// Set a custom base URL (useful for testing or manual configuration)
  static void setCustomBaseUrl(String? url) {
    _customBaseUrl = url;
  }

  /// Get the effective base URL (custom > production > development)
  static String get effectiveBaseUrl {
    if (_customBaseUrl != null) {
      return _customBaseUrl!;
    }
    return baseUrl;
  }

  /// Get the effective auth base URL
  static String get effectiveAuthBaseUrl {
    if (_customBaseUrl != null) {
      return '$_customBaseUrl/auth';
    }
    return authBaseUrl;
  }
}
