import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/widgets/login/login_header.dart';
import 'package:financial_app/widgets/login/login_form.dart';
import 'package:financial_app/widgets/login/social_login.dart';
import 'package:financial_app/widgets/login/toggle_auth.dart';
import 'package:financial_app/utils/design_tokens.dart';

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

  @override
  void initState() { super.initState(); _clearFormFields(); }

  void _clearFormFields() { _emailController.clear(); _passwordController.clear(); _nameController.clear(); }

  @override
  void dispose() { _emailController.dispose(); _passwordController.dispose(); _nameController.dispose(); super.dispose(); }

  void _toggleAuthMode() { setState(() { _isLogin = !_isLogin; }); }

  bool _isValidEmail(String email) => RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  bool _isStrongPassword(String password) => password.length >= 8;

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ErrorHandlerService.showWarningSnackbar(context, 'Silakan isi semua field'); return;
    }
    if (!_isValidEmail(_emailController.text.trim())) {
      ErrorHandlerService.showWarningSnackbar(context, 'Format email tidak valid'); return;
    }
    setState(() => _isLoading = true);
    final ctx = context;
    try {
      await context.read<AuthController>().login(_emailController.text.trim(), _passwordController.text);
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      if (!ctx.mounted) return;
      if (!onboardingCompleted) {
        Navigator.pushReplacementNamed(ctx, '/onboarding');
      } else {
        final hasPin = await ctx.read<AuthController>().hasPin();
        if (!ctx.mounted) return;
        if (!hasPin) { Navigator.pushReplacementNamed(ctx, '/pin-setup'); }
        else { Navigator.pushReplacementNamed(ctx, '/home'); }
      }
    } catch (e) {
      LoggerService.error('Error during login', error: e);
      if (ctx.mounted) {
        ErrorHandlerService.showErrorSnackbar(ctx, ErrorHandlerService.getUserFriendlyMessage(e), onRetry: _handleLogin);
      }
    } finally { setState(() => _isLoading = false); }
  }

  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ErrorHandlerService.showWarningSnackbar(context, 'Silakan isi semua field'); return;
    }
    if (!_isValidEmail(_emailController.text.trim())) { ErrorHandlerService.showWarningSnackbar(context, 'Format email tidak valid'); return; }
    if (!_isStrongPassword(_passwordController.text)) { ErrorHandlerService.showWarningSnackbar(context, 'Password minimal 8 karakter'); return; }
    setState(() => _isLoading = true);
    try {
      await context.read<AuthController>().register(_emailController.text.trim(), _passwordController.text, _nameController.text.trim());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', false);
      if (mounted) Navigator.pushReplacementNamed(context, '/pin-setup');
    } catch (e) {
      LoggerService.error('Error during registration', error: e);
      if (mounted) ErrorHandlerService.showErrorSnackbar(context, ErrorHandlerService.getUserFriendlyMessage(e), onRetry: _handleRegister);
    } finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.surfaceDark,
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: _isLogin ? const LoginHeader() : const RegisterHeader()),
                  const SizedBox(height: 40),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isLogin
                        ? LoginForm(emailController: _emailController, passwordController: _passwordController, obscurePassword: _obscurePassword, onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword), onLoginPressed: _handleLogin, isLoading: _isLoading)
                        : RegisterForm(nameController: _nameController, emailController: _emailController, passwordController: _passwordController, obscurePassword: _obscurePassword, onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword), onRegisterPressed: _handleRegister, isLoading: _isLoading),
                  ),
                  const SizedBox(height: 30),
                  const SocialLogin(),
                  const SizedBox(height: 20),
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
