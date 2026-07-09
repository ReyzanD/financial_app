import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/pin_auth_service.dart';
import '../services/error_handler_service.dart';
import '../services/logger_service.dart';
import '../widgets/common/offline_indicator.dart';
import '../widgets/login/login_header.dart';
import '../widgets/login/login_form.dart';
import '../widgets/login/social_login.dart';
import '../widgets/login/toggle_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Clear all form fields when screen is initialized
    // This ensures no credentials from previous user are shown
    _clearFormFields();
  }

  void _clearFormFields() {
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  bool _isStrongPassword(String password) {
    return password.length >= 8;
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ErrorHandlerService.showWarningSnackbar(
        context,
        'Silakan isi semua field',
      );
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      ErrorHandlerService.showWarningSnackbar(
        context,
        'Format email tidak valid',
      );
      return;
    }

    setState(() => _isLoading = true);

    final ctx = context;

    try {
      final result = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (result != null) {
        // Check if user has completed onboarding
        final prefs = await SharedPreferences.getInstance();
        final onboardingCompleted =
            prefs.getBool('onboarding_completed') ?? false;

        if (!ctx.mounted) return;
        if (!onboardingCompleted) {
          // New user - redirect to onboarding
          Navigator.pushReplacementNamed(ctx, '/onboarding');
        } else {
          // Check if user has PIN set up
          final pinAuthService = PinAuthService();
          final hasPin = await pinAuthService.hasPin();

          if (!ctx.mounted) return;
          if (!hasPin) {
            // No PIN - redirect to PIN setup (mandatory)
            Navigator.pushReplacementNamed(ctx, '/pin-setup');
          } else {
            // Has PIN - go to home (PIN unlock handled by AuthGate)
            Navigator.pushReplacementNamed(ctx, '/home');
          }
        }
      }
    } catch (e) {
      LoggerService.error('Error during login', error: e);
      if (ctx.mounted) {
        ErrorHandlerService.showErrorSnackbar(
          ctx,
          ErrorHandlerService.getUserFriendlyMessage(e),
          onRetry: _handleLogin,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ErrorHandlerService.showWarningSnackbar(
        context,
        'Silakan isi semua field',
      );
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      ErrorHandlerService.showWarningSnackbar(
        context,
        'Format email tidak valid',
      );
      return;
    }

    if (!_isStrongPassword(_passwordController.text)) {
      ErrorHandlerService.showWarningSnackbar(
        context,
        'Password minimal 8 karakter',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );

      if (result != null) {
        // Reset onboarding for new users
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_completed', false);

        // Auto-login successful, redirect to PIN setup
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/pin-setup');
        }
      }
    } catch (e) {
      LoggerService.error('Error during registration', error: e);
      if (mounted) {
        ErrorHandlerService.showErrorSnackbar(
          context,
          ErrorHandlerService.getUserFriendlyMessage(e),
          onRetry: _handleRegister,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Header dengan animasi
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child:
                        _isLogin ? const LoginHeader() : const RegisterHeader(),
                  ),

                  const SizedBox(height: 40),

                  // Form
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child:
                        _isLogin
                            ? LoginForm(
                              emailController: _emailController,
                              passwordController: _passwordController,
                              obscurePassword: _obscurePassword,
                              onToggleObscure: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              onLoginPressed: _handleLogin,
                              isLoading: _isLoading,
                            )
                            : RegisterForm(
                              nameController: _nameController,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              obscurePassword: _obscurePassword,
                              onToggleObscure: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              onRegisterPressed: _handleRegister,
                              isLoading: _isLoading,
                            ),
                  ),

                  const SizedBox(height: 30),

                  // Social Login
                  const SocialLogin(),

                  const SizedBox(height: 20),

                  // Toggle Auth Mode
                  ToggleAuth(isLogin: _isLogin, onToggle: _toggleAuthMode),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
