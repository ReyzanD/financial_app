import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:financial_app/features/auth/presentation/screens/login_screen.dart';
import 'package:financial_app/features/auth/presentation/screens/pin_setup_screen.dart';
import 'package:financial_app/features/auth/presentation/screens/pin_unlock_screen.dart';
import 'package:financial_app/features/home/presentation/screens/home_screen.dart';
import 'package:financial_app/utils/design_tokens.dart';

/// Authentication Gate - Routes users based on their auth status
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  Widget? _targetScreen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _determineRoute());
  }

  Future<void> _determineRoute() async {
    final ctrl = context.read<AuthController>();
    try {
      final hasToken = await ctrl.hasValidToken();
      if (!hasToken) {
        setState(() {
          _targetScreen = const LoginScreen();
          _isLoading = false;
        });
        return;
      }
      final hasPin = await ctrl.hasPin();
      if (!hasPin) {
        setState(() {
          _targetScreen = const PinSetupScreen();
          _isLoading = false;
        });
        return;
      }
      final shouldLock = await ctrl.shouldAutoLock();
      final biometricShouldLock = await ctrl.biometricService.shouldLock();

      if (shouldLock || biometricShouldLock) {
        setState(() {
          _targetScreen = const PinUnlockScreen();
          _isLoading = false;
        });
      } else {
        setState(() {
          _targetScreen = const HomeScreen();
          _isLoading = false;
        });
      }
    } catch (e) {
      LoggerService.error('Error determining route', error: e);
      if (mounted) {
        ErrorHandlerService.showErrorSnackbar(context, ErrorHandlerService.getUserFriendlyMessage(e));
      }
      setState(() {
        _targetScreen = const LoginScreen();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: DesignTokens.backgroundDark,
        body: Column(
          children: [
            const OfflineIndicator(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: DesignTokens.primaryColor),
                    const SizedBox(height: DesignTokens.spacing4),
                    const Text('Loading...', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return _targetScreen ?? const LoginScreen();
  }
}
