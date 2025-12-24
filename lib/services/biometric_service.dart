import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk biometric authentication (fingerprint/Face ID)
class BiometricService {
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _autoLockEnabledKey = 'auto_lock_enabled';
  static const String _autoLockTimeoutKey = 'auto_lock_timeout';
  static const String _lastUnlockTimeKey = 'last_unlock_time';
  static const int _defaultAutoLockTimeout = 300; // 5 minutes in seconds

  final LocalAuthentication _localAuth = LocalAuthentication();

  // Singleton pattern
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  /// Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      LoggerService.debug('[BiometricService] Device supported: $isSupported');
      return isSupported;
    } catch (e) {
      LoggerService.error('[BiometricService] Error checking device support', error: e);
      return false;
    }
  }

  /// Check if biometric authentication is available
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await this.isDeviceSupported();
      final available = canCheck && isDeviceSupported;
      LoggerService.debug('[BiometricService] Biometric available: $available');
      return available;
    } catch (e) {
      LoggerService.error('[BiometricService] Error checking availability', error: e);
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final biometrics = await _localAuth.getAvailableBiometrics();
      LoggerService.debug('[BiometricService] Available biometrics: $biometrics');
      return biometrics;
    } catch (e) {
      LoggerService.error('[BiometricService] Error getting biometrics', error: e);
      return [];
    }
  }

  /// Check if biometric is enabled in settings
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      LoggerService.error('[BiometricService] Error checking enabled status', error: e);
      return false;
    }
  }

  /// Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, enabled);
      LoggerService.info('[BiometricService] Biometric ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      LoggerService.error('[BiometricService] Error setting enabled status', error: e);
      rethrow;
    }
  }

  /// Authenticate dengan biometric
  Future<bool> authenticate({
    String reason = 'Autentikasi diperlukan untuk melanjutkan',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final isAvailable = await this.isAvailable();
      if (!isAvailable) {
        LoggerService.warning('[BiometricService] Biometric not available');
        return false;
      }

      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) {
        LoggerService.warning('[BiometricService] Biometric not enabled');
        return false;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        await _updateLastUnlockTime();
        LoggerService.success('[BiometricService] Authentication successful');
      } else {
        LoggerService.warning('[BiometricService] Authentication failed or cancelled');
      }

      return didAuthenticate;
    } on PlatformException catch (e) {
      LoggerService.error('[BiometricService] Platform exception during authentication', error: e);
      return false;
    } catch (e) {
      LoggerService.error('[BiometricService] Error during authentication', error: e);
      return false;
    }
  }

  /// Check if auto-lock is enabled
  Future<bool> isAutoLockEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_autoLockEnabledKey) ?? false;
    } catch (e) {
      LoggerService.error('[BiometricService] Error checking auto-lock status', error: e);
      return false;
    }
  }

  /// Enable/disable auto-lock
  Future<void> setAutoLockEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoLockEnabledKey, enabled);
      LoggerService.info('[BiometricService] Auto-lock ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      LoggerService.error('[BiometricService] Error setting auto-lock status', error: e);
      rethrow;
    }
  }

  /// Get auto-lock timeout (in seconds)
  Future<int> getAutoLockTimeout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_autoLockTimeoutKey) ?? _defaultAutoLockTimeout;
    } catch (e) {
      LoggerService.error('[BiometricService] Error getting auto-lock timeout', error: e);
      return _defaultAutoLockTimeout;
    }
  }

  /// Set auto-lock timeout (in seconds)
  Future<void> setAutoLockTimeout(int seconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_autoLockTimeoutKey, seconds);
      LoggerService.info('[BiometricService] Auto-lock timeout set to $seconds seconds');
    } catch (e) {
      LoggerService.error('[BiometricService] Error setting auto-lock timeout', error: e);
      rethrow;
    }
  }

  /// Check if app should be locked (based on auto-lock timeout)
  Future<bool> shouldLock() async {
    try {
      final isEnabled = await isAutoLockEnabled();
      if (!isEnabled) {
        return false;
      }

      final lastUnlockTime = await _getLastUnlockTime();
      if (lastUnlockTime == null) {
        return true; // Never unlocked, should lock
      }

      final timeout = await getAutoLockTimeout();
      final now = DateTime.now();
      final difference = now.difference(lastUnlockTime).inSeconds;

      return difference >= timeout;
    } catch (e) {
      LoggerService.error('[BiometricService] Error checking lock status', error: e);
      return true; // Default to locked on error
    }
  }

  /// Update last unlock time
  Future<void> _updateLastUnlockTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastUnlockTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      LoggerService.error('[BiometricService] Error updating unlock time', error: e);
    }
  }

  /// Get last unlock time
  Future<DateTime?> _getLastUnlockTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastUnlockTimeKey);
      if (timestamp == null) {
        return null;
      }
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      LoggerService.error('[BiometricService] Error getting unlock time', error: e);
      return null;
    }
  }

  /// Clear last unlock time (for logout)
  Future<void> clearUnlockTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastUnlockTimeKey);
      LoggerService.info('[BiometricService] Unlock time cleared');
    } catch (e) {
      LoggerService.error('[BiometricService] Error clearing unlock time', error: e);
    }
  }

  /// Stop authentication (if in progress)
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
      LoggerService.debug('[BiometricService] Authentication stopped');
    } catch (e) {
      LoggerService.error('[BiometricService] Error stopping authentication', error: e);
    }
  }
}

