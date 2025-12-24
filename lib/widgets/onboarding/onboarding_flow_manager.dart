import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/services/logger_service.dart';

/// Manager untuk onboarding flow dengan progress tracking
class OnboardingFlowManager {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _onboardingProgressKey = 'onboarding_progress';
  static const String _onboardingSkippedKey = 'onboarding_skipped';
  static const String _permissionsRequestedKey = 'permissions_requested';

  /// Check if onboarding is completed
  static Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingCompletedKey) ?? false;
    } catch (e) {
      LoggerService.error('Error checking onboarding status', error: e);
      return false;
    }
  }

  /// Check if onboarding was skipped
  static Future<bool> wasOnboardingSkipped() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingSkippedKey) ?? false;
    } catch (e) {
      LoggerService.error('Error checking onboarding skip status', error: e);
      return false;
    }
  }

  /// Mark onboarding as completed
  static Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);
      await prefs.setBool(_onboardingSkippedKey, false);
      LoggerService.info('Onboarding marked as completed');
    } catch (e) {
      LoggerService.error('Error completing onboarding', error: e);
    }
  }

  /// Mark onboarding as skipped
  static Future<void> skipOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingSkippedKey, true);
      await prefs.setBool(_onboardingCompletedKey, true);
      LoggerService.info('Onboarding marked as skipped');
    } catch (e) {
      LoggerService.error('Error skipping onboarding', error: e);
    }
  }

  /// Save onboarding progress
  static Future<void> saveProgress(int currentPage, int totalPages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progress = currentPage / totalPages;
      await prefs.setDouble(_onboardingProgressKey, progress);
      LoggerService.debug('Onboarding progress saved: ${(progress * 100).toStringAsFixed(0)}%');
    } catch (e) {
      LoggerService.error('Error saving onboarding progress', error: e);
    }
  }

  /// Get onboarding progress
  static Future<double> getProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_onboardingProgressKey) ?? 0.0;
    } catch (e) {
      LoggerService.error('Error getting onboarding progress', error: e);
      return 0.0;
    }
  }

  /// Check if permissions were already requested
  static Future<bool> werePermissionsRequested() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_permissionsRequestedKey) ?? false;
    } catch (e) {
      LoggerService.error('Error checking permissions status', error: e);
      return false;
    }
  }

  /// Mark permissions as requested
  static Future<void> markPermissionsRequested() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_permissionsRequestedKey, true);
      LoggerService.info('Permissions marked as requested');
    } catch (e) {
      LoggerService.error('Error marking permissions as requested', error: e);
    }
  }

  /// Reset onboarding (for testing or re-onboarding)
  static Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingCompletedKey);
      await prefs.remove(_onboardingSkippedKey);
      await prefs.remove(_onboardingProgressKey);
      await prefs.remove(_permissionsRequestedKey);
      LoggerService.info('Onboarding reset');
    } catch (e) {
      LoggerService.error('Error resetting onboarding', error: e);
    }
  }
}

