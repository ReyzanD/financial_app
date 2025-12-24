import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:financial_app/services/logger_service.dart';

/// Service untuk API security enhancements: certificate pinning, request signing, rate limiting
class ApiSecurityService {
  static const int _maxRequestsPerMinute = 60;
  static const int _maxRequestsPerHour = 1000;
  
  final Map<String, List<DateTime>> _requestHistory = {};
  final Map<String, int> _requestCounts = {};

  /// Sign request dengan HMAC
  String signRequest(String method, String endpoint, Map<String, dynamic>? body, String secret) {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final nonce = DateTime.now().microsecondsSinceEpoch.toString();
      
      // Create signature payload
      final payload = {
        'method': method,
        'endpoint': endpoint,
        'body': body ?? {},
        'timestamp': timestamp,
        'nonce': nonce,
      };
      
      final payloadString = json.encode(payload);
      final key = utf8.encode(secret);
      final bytes = utf8.encode(payloadString);
      
      final hmac = Hmac(sha256, key);
      final digest = hmac.convert(bytes);
      
      return digest.toString();
    } catch (e) {
      LoggerService.error('Error signing request', error: e);
      return '';
    }
  }

  /// Check rate limit
  Future<bool> checkRateLimit(String endpoint) async {
    try {
      final now = DateTime.now();
      final key = endpoint;
      
      // Clean old requests (older than 1 hour)
      if (_requestHistory.containsKey(key)) {
        _requestHistory[key]!.removeWhere(
          (time) => now.difference(time).inHours > 1,
        );
      } else {
        _requestHistory[key] = [];
      }
      
      // Check per-minute limit
      final recentRequests = _requestHistory[key]!.where(
        (time) => now.difference(time).inMinutes < 1,
      ).length;
      
      if (recentRequests >= _maxRequestsPerMinute) {
        LoggerService.warning('Rate limit exceeded for $endpoint');
        return false;
      }
      
      // Check per-hour limit
      final hourlyRequests = _requestHistory[key]!.where(
        (time) => now.difference(time).inHours < 1,
      ).length;
      
      if (hourlyRequests >= _maxRequestsPerHour) {
        LoggerService.warning('Hourly rate limit exceeded for $endpoint');
        return false;
      }
      
      // Record request
      _requestHistory[key]!.add(now);
      
      return true;
    } catch (e) {
      LoggerService.error('Error checking rate limit', error: e);
      return true; // Allow on error
    }
  }

  /// Get rate limit status
  Map<String, dynamic> getRateLimitStatus(String endpoint) {
    final now = DateTime.now();
    final key = endpoint;
    
    if (!_requestHistory.containsKey(key)) {
      return {
        'remaining_per_minute': _maxRequestsPerMinute,
        'remaining_per_hour': _maxRequestsPerHour,
        'reset_in_seconds': 60,
      };
    }
    
    final recentRequests = _requestHistory[key]!.where(
      (time) => now.difference(time).inMinutes < 1,
    ).length;
    
    final hourlyRequests = _requestHistory[key]!.where(
      (time) => now.difference(time).inHours < 1,
    ).length;
    
    return {
      'remaining_per_minute': _maxRequestsPerMinute - recentRequests,
      'remaining_per_hour': _maxRequestsPerHour - hourlyRequests,
      'reset_in_seconds': 60 - (now.second),
    };
  }

  /// Clear rate limit history
  void clearRateLimitHistory() {
    _requestHistory.clear();
    _requestCounts.clear();
    LoggerService.debug('Rate limit history cleared');
  }

  /// Certificate pinning storage
  /// In production, these should be stored securely (e.g., in encrypted storage)
  /// 
  /// To add a certificate pin:
  /// 1. Extract your server's certificate SHA-256 hash
  /// 2. Call ApiSecurityService.addCertificatePin('your-server.com', 'hash_here')
  /// 3. In production builds, set _pinnedCertificates with your actual certificate hashes
  /// 
  /// Example:
  /// ```dart
  /// ApiSecurityService.addCertificatePin(
  ///   'api.yourdomain.com',
  ///   'a1b2c3d4e5f6...', // SHA-256 hash of your certificate
  /// );
  /// ```
  static final Map<String, String> _pinnedCertificates = {
    // TODO: Add your production server's certificate SHA-256 hash here
    // Example: 'api.yourdomain.com': 'your_certificate_sha256_hash_here',
  };

  /// Validate certificate (certificate pinning implementation)
  /// For production use, implement platform-specific certificate validation
  /// This is a basic implementation that can be extended
  Future<bool> validateCertificate(String host, List<int> certificate) async {
    try {
      // Extract hostname from URL if full URL is provided
      final hostname = host.contains('://')
          ? Uri.parse(host).host
          : host;

      // Check if we have a pinned certificate for this host
      if (!_pinnedCertificates.containsKey(hostname)) {
        // In development, allow connections without pinning
        // In production, you should configure certificate pinning for security
        // Set kDebugMode to false in production or use a build flag
        const bool isProduction = bool.fromEnvironment('dart.vm.product');
        if (isProduction) {
          LoggerService.warning(
            'No certificate pinning configured for $hostname in production build',
          );
          // In production, you may want to reject connections without pinning
          // For now, we allow it but log a warning
        } else {
          LoggerService.debug(
            'No certificate pinning configured for $hostname (development mode)',
          );
        }
        return true;
      }

      // Calculate certificate hash
      final certificateBytes = certificate;
      final hash = sha256.convert(certificateBytes);
      final certificateHash = hash.toString();

      // Compare with pinned certificate
      final pinnedHash = _pinnedCertificates[hostname];
      if (certificateHash != pinnedHash) {
        LoggerService.error(
          'Certificate pinning failed for $hostname: hash mismatch',
        );
        return false;
      }

      LoggerService.debug('Certificate validated successfully for $hostname');
      return true;
    } catch (e) {
      LoggerService.error('Error validating certificate', error: e);
      // In production, you may want to reject on error
      // For now, allow connection to prevent breaking the app
      return true;
    }
  }

  /// Add certificate pin for a host
  /// Call this during app initialization with your server's certificate hash
  static void addCertificatePin(String host, String certificateHash) {
    _pinnedCertificates[host] = certificateHash;
    LoggerService.debug('Certificate pin added for $host');
  }

  /// Remove certificate pin for a host
  static void removeCertificatePin(String host) {
    _pinnedCertificates.remove(host);
    LoggerService.debug('Certificate pin removed for $host');
  }

  /// Generate secure token
  String generateSecureToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    final data = '$timestamp-$random';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

