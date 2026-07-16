import 'dart:async';
import 'package:financial_app/services/auth_service.dart';
import 'package:financial_app/services/pin_auth_service.dart';
import 'package:financial_app/services/biometric_service.dart';
import 'package:financial_app/widgets/onboarding/onboarding_flow_manager.dart';

/// Auth Repository - delegates to Auth/Pin/Biometric services and onboarding manager.
class AuthRepository {
  final AuthService _authService;
  final PinAuthService _pinAuthService;
  final BiometricService _biometricService;

  AuthRepository({
    AuthService? authService,
    PinAuthService? pinAuthService,
    BiometricService? biometricService,
  })  : _authService = authService ?? AuthService(),
        _pinAuthService = pinAuthService ?? PinAuthService(),
        _biometricService = biometricService ?? BiometricService();

  Future<bool> hasValidToken() => _authService.hasValidToken();
  Future<Map<String, dynamic>> login(String email, String password) async =>
      (await _authService.login(email, password)) ?? {};
  Future<Map<String, dynamic>> register(String email, String password, String name) async =>
      (await _authService.register(email, password, name)) ?? {};
  Future<void> logout() => _authService.logout();

  Future<bool> hasPin() => _pinAuthService.hasPin();
  Future<bool> shouldAutoLock() => _pinAuthService.shouldAutoLock();
  Future<int> getPinLength() => _pinAuthService.getPinLength();
  Future<int> getRemainingAttempts() => _pinAuthService.getRemainingAttempts();
  Future<Duration?> getLockRemainingTime() => _pinAuthService.getLockRemainingTime();
  Future<bool> verifyPin(String pin) => _pinAuthService.verifyPin(pin);
  Future<void> createPin(String pin) => _pinAuthService.createPin(pin);
  Future<void> clearPin() => _pinAuthService.clearPin();

  Future<bool> get biometricAvailable => _biometricService.isAvailable();
  Future<bool> get biometricEnabled => _biometricService.isBiometricEnabled();
  Future<bool> authenticate({required String reason}) =>
      _biometricService.authenticate(reason: reason);
  Future<dynamic> getAvailableBiometrics() => _biometricService.getAvailableBiometrics();

  BiometricService get biometricService => _biometricService;

  Future<bool> isOnboardingCompleted() => OnboardingFlowManager.isOnboardingCompleted();
  Future<void> completeOnboarding() => OnboardingFlowManager.completeOnboarding();
  Future<void> resetOnboarding() => OnboardingFlowManager.resetOnboarding();
}
