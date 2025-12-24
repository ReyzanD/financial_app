import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/pin_auth_service.dart';
import '../services/error_handler_service.dart';
import '../services/logger_service.dart';
import '../widgets/login/login_header.dart';
import '../widgets/login/login_form.dart';
import '../widgets/login/social_login.dart';
import '../widgets/login/toggle_auth.dart';

class LoginUI extends StatelessWidget {
  const LoginUI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFF8B5FBF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5FBF),
          secondary: Color(0xFF6A3093),
          surface: Color(0xFF1A1A1A),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

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

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ErrorHandlerService.showWarningSnackbar(
        context,
        'Silakan isi semua field',
      );
      return;
    }

    setState(() => _isLoading = true);

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

        if (!onboardingCompleted) {
          // New user - redirect to onboarding
          Navigator.pushReplacementNamed(context, '/onboarding');
        } else {
          // Check if user has PIN set up
          final pinAuthService = PinAuthService();
          final hasPin = await pinAuthService.hasPin();

          if (!hasPin) {
            // No PIN - redirect to PIN setup (mandatory)
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/pin-setup');
            }
          } else {
            // Has PIN - go to home (PIN unlock handled by AuthGate)
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          }
        }
      }
    } catch (e) {
      LoggerService.error('Error during login', error: e);
      if (mounted) {
        ErrorHandlerService.showErrorSnackbar(
          context,
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

    setState(() => _isLoading = true);

    try {
      final result = await _authService.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );

      if (result != null) {
        ErrorHandlerService.showSuccessSnackbar(
          context,
          'Registrasi berhasil! Silakan login.',
        );
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        setState(() {
          _isLogin = true;
        });
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Header dengan animasi
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isLogin ? const LoginHeader() : const RegisterHeader(),
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
    );
  }
}
