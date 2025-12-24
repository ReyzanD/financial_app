import 'package:flutter/material.dart';
import 'package:financial_app/services/auth_service.dart';
import 'package:financial_app/services/pin_auth_service.dart';
import 'package:financial_app/services/biometric_service.dart';
import 'package:financial_app/Screen/login_screen.dart';
import 'package:financial_app/Screen/pin_setup_screen.dart';
import 'package:financial_app/Screen/pin_unlock_screen.dart';
import 'package:financial_app/Screen/home_screen.dart';

/// Authentication Gate - Routes users based on their auth status
///
/// Flow:
/// 1. No token → LoginScreen
/// 2. Has token, no PIN → PinSetupScreen (mandatory)
/// 3. Has token, has PIN → PinUnlockScreen
/// 4. Unlocked → HomeScreen
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  final PinAuthService _pinAuthService = PinAuthService();
  final BiometricService _biometricService = BiometricService();

  bool _isLoading = true;
  Widget? _targetScreen;

  @override
  void initState() {
    super.initState();
    _determineRoute();
  }

  Future<void> _determineRoute() async {
    try {
      // Check if user has a valid auth token
      final hasToken = await _authService.hasValidToken();

      if (!hasToken) {
        // No token → Login required
        setState(() {
          _targetScreen = const LoginScreen();
          _isLoading = false;
        });
        return;
      }

      // Has token, check PIN status
      final hasPin = await _pinAuthService.hasPin();

      if (!hasPin) {
        // Has token but no PIN → PIN setup required (mandatory for existing users)
        setState(() {
          _targetScreen = const PinSetupScreen();
          _isLoading = false;
        });
        return;
      }

      // Has token and PIN → Check if should auto-lock
      final shouldLock = await _pinAuthService.shouldAutoLock();
      
      // Also check biometric auto-lock
      final biometricShouldLock = await _biometricService.shouldLock();

      if (shouldLock || biometricShouldLock) {
        // Needs to unlock with PIN or biometric
        setState(() {
          _targetScreen = const PinUnlockScreen();
          _isLoading = false;
        });
      } else {
        // Recently unlocked, go straight to home
        setState(() {
          _targetScreen = const HomeScreen();
          _isLoading = false;
        });
      }
    } catch (e) {
      // On error, default to login
      setState(() {
        _targetScreen = const LoginScreen();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF8B5FBF)),
              SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return _targetScreen ?? const LoginScreen();
  }
}
