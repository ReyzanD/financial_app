import 'package:flutter/foundation.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/features/onboarding/data/repositories/onboarding_repository.dart';

class OnboardingController extends ChangeNotifier {
  final OnboardingRepository _repository;

  OnboardingController({OnboardingRepository? repository})
      : _repository = repository ?? OnboardingRepository();

  bool _isLoading = false;
  int _currentPage = 0;
  bool _isComplete = false;

  bool get isLoading => _isLoading;
  int get currentPage => _currentPage;
  bool get isComplete => _isComplete;

  void setPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.completeOnboarding();
      _isComplete = true;
    } catch (e) {
      LoggerService.error('Error saving onboarding state', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkOnboardingComplete() async {
    return await _repository.checkOnboardingComplete();
  }
}
