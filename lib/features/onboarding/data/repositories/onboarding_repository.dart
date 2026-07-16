import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding Repository - wraps SharedPreferences access for onboarding state.
class OnboardingRepository {
  static const String _onboardingCompleteKey = 'onboarding_complete';

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }

  Future<bool> checkOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }
}
