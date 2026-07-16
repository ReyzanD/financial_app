import 'package:flutter/foundation.dart';
import 'package:financial_app/services/biometric_service.dart';
import 'package:financial_app/features/auth/data/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _repository;

  AuthController({AuthRepository? repository}) : _repository = repository ?? AuthRepository();

  Future<bool> hasValidToken() => _repository.hasValidToken();
  Future<bool> hasPin() => _repository.hasPin();
  Future<bool> shouldAutoLock() => _repository.shouldAutoLock();
  Future<int> getPinLength() => _repository.getPinLength();
  Future<int> getRemainingAttempts() => _repository.getRemainingAttempts();
  Future<Duration?> getLockRemainingTime() => _repository.getLockRemainingTime();
  Future<bool> verifyPin(String pin) => _repository.verifyPin(pin);
  Future<void> createPin(String pin) => _repository.createPin(pin);
  Future<void> clearPin() => _repository.clearPin();

  Future<bool> get biometricAvailable => _repository.biometricAvailable;
  Future<bool> get biometricEnabled => _repository.biometricEnabled;
  Future<bool> authenticate({required String reason}) => _repository.authenticate(reason: reason);

  BiometricService get biometricService => _repository.biometricService;

  Future<Map<String, dynamic>> login(String email, String password) async =>
      await _repository.login(email, password);
  Future<Map<String, dynamic>> register(String email, String password, String name) async =>
      await _repository.register(email, password, name);
  Future<void> logout() => _repository.logout();

  Future<bool> isOnboardingCompleted() => _repository.isOnboardingCompleted();

  Future<void> setOnboardingCompleted(bool value) async {
    if (value) {
      await _repository.completeOnboarding();
    } else {
      await _repository.resetOnboarding();
    }
  }

  Future<dynamic> getAvailableBiometrics() => _repository.getAvailableBiometrics();
}
