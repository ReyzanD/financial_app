/// Centralized application configuration
/// 
/// This file manages environment-specific settings like API base URLs.
/// For production builds, use build flags or environment variables.
class AppConfig {
  // Development API URL (for Android emulator)
  static const String _devBaseUrl = 'http://10.0.2.2:5000/api/v1';
  
  // Production API URL - Update this with your Render URL after deployment
  // Format: https://your-app-name.onrender.com/api/v1
  static const String _prodBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://your-app-name.onrender.com/api/v1',
  );
  
  /// Determine if we're in production mode
  /// 
  /// Checks for production build flag or environment variable.
  /// Defaults to false (development mode).
  static bool get isProduction {
    // Check if PRODUCTION flag is set
    const isProdFlag = bool.fromEnvironment('PRODUCTION', defaultValue: false);
    // Also check if API_BASE_URL is set (indicates production)
    const apiUrlSet = String.fromEnvironment('API_BASE_URL', defaultValue: '') != '';
    return isProdFlag || apiUrlSet;
  }
  
  /// Get the base URL for API calls
  /// 
  /// Returns production URL if in production mode, otherwise development URL.
  static String get baseUrl {
    if (isProduction || _prodBaseUrl != 'https://your-app-name.onrender.com/api/v1') {
      return _prodBaseUrl;
    }
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

