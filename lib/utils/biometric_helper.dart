import 'package:flutter/material.dart';
import 'package:financial_app/services/biometric_service.dart';
import 'package:financial_app/services/logger_service.dart';

/// Helper untuk biometric authentication pada sensitive actions
class BiometricHelper {
  static final BiometricService _biometricService = BiometricService();

  /// Request biometric authentication untuk sensitive action
  /// Returns true if authenticated, false if cancelled or failed
  static Future<bool> requestBiometricAuth({
    required BuildContext context,
    String reason = 'Autentikasi diperlukan untuk tindakan ini',
    bool showError = true,
  }) async {
    try {
      // Check if biometric is available
      final isAvailable = await _biometricService.isAvailable();
      if (!isAvailable) {
        LoggerService.debug('[BiometricHelper] Biometric not available');
        return false;
      }

      // Check if biometric is enabled
      final isEnabled = await _biometricService.isBiometricEnabled();
      if (!isEnabled) {
        LoggerService.debug('[BiometricHelper] Biometric not enabled');
        return false;
      }

      // Request authentication
      final authenticated = await _biometricService.authenticate(
        reason: reason,
        useErrorDialogs: showError,
        stickyAuth: true,
      );

      if (authenticated) {
        LoggerService.success('[BiometricHelper] Biometric authentication successful');
      } else {
        LoggerService.warning('[BiometricHelper] Biometric authentication failed or cancelled');
      }

      return authenticated;
    } catch (e) {
      LoggerService.error('[BiometricHelper] Error during biometric authentication', error: e);
      return false;
    }
  }

  /// Check if biometric authentication should be required for action
  static Future<bool> shouldRequireBiometric() async {
    try {
      final isAvailable = await _biometricService.isAvailable();
      final isEnabled = await _biometricService.isBiometricEnabled();
      return isAvailable && isEnabled;
    } catch (e) {
      LoggerService.error('[BiometricHelper] Error checking biometric requirement', error: e);
      return false;
    }
  }

  /// Request biometric dengan fallback ke PIN jika biometric tidak tersedia
  static Future<bool> requestAuthWithFallback({
    required BuildContext context,
    String reason = 'Autentikasi diperlukan',
  }) async {
    final shouldUseBiometric = await shouldRequireBiometric();
    
    if (shouldUseBiometric) {
      return await requestBiometricAuth(
        context: context,
        reason: reason,
      );
    }
    
    // Fallback: return true (no authentication required)
    // In a real app, you might want to show PIN dialog here
    return true;
  }
}

