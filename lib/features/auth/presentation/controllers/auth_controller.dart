import 'package:flutter/foundation.dart';
import 'package:financial_app/services/auth_service.dart';
import 'package:financial_app/services/pin_auth_service.dart';
import 'package:financial_app/services/biometric_service.dart';
import 'package:financial_app/widgets/onboarding/onboarding_flow_manager.dart';

class AuthController extends ChangeNotifier {
  final AuthService authService;
  final PinAuthService pinAuthService;
  final BiometricService biometricService;

  AuthController({AuthService? authService, PinAuthService? pinAuthService, BiometricService? biometricService})
    : authService = authService ?? AuthService(),
      pinAuthService = pinAuthService ?? PinAuthService(),
      biometricService = biometricService ?? BiometricService();

  Future<bool> hasValidToken() => authService.hasValidToken();
  Future<bool> hasPin() => pinAuthService.hasPin();
  Future<bool> shouldAutoLock() => pinAuthService.shouldAutoLock();
  Future<int> getPinLength() => pinAuthService.getPinLength();
  Future<int> getRemainingAttempts() => pinAuthService.getRemainingAttempts();
  Future<Duration?> getLockRemainingTime() => pinAuthService.getLockRemainingTime();
  Future<bool> verifyPin(String pin) => pinAuthService.verifyPin(pin);
  Future<void> createPin(String pin) => pinAuthService.createPin(pin);
  Future<void> clearPin() => pinAuthService.clearPin();

  Future<bool> get biometricAvailable => biometricService.isAvailable();
  Future<bool> get biometricEnabled => biometricService.isBiometricEnabled();
  Future<bool> authenticate({required String reason}) => biometricService.authenticate(reason: reason);

  Future<Map<String, dynamic>> login(String email, String password) async =>
      (await authService.login(email, password)) ?? {};
  Future<Map<String, dynamic>> register(String email, String password, String name) async =>
      (await authService.register(email, password, name)) ?? {};
  Future<void> logout() => authService.logout();

  Future<bool> isOnboardingCompleted() => OnboardingFlowManager.isOnboardingCompleted();

  Future<void> setOnboardingCompleted(bool value) async {
    if (value) {
      await OnboardingFlowManager.completeOnboarding();
    } else {
      await OnboardingFlowManager.resetOnboarding();
    }
  }

  Future<dynamic> getAvailableBiometrics() => biometricService.getAvailableBiometrics();
}
