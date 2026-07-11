import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/services/logger_service.dart';

class OnboardingController extends ChangeNotifier {
  bool _isLoading = false;
  int _currentPage = 0;
  bool _isComplete = false;

  bool get isLoading => _isLoading;
  int get currentPage => _currentPage;
  bool get isComplete => _isComplete;

  void setPage(int page) { _currentPage = page; notifyListeners(); }

  Future<void> completeOnboarding() async {
    _isLoading = true; notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      _isComplete = true;
    } catch (e) {
      LoggerService.error('Error saving onboarding state', error: e);
    } finally { _isLoading = false; notifyListeners(); }
  }

  Future<bool> checkOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }
}
