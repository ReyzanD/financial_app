import 'package:flutter/material.dart';
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

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
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
                        onLoginPressed: () {
                          Navigator.pushReplacementNamed(context, '/home');
                          // Handle login
                        },
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
                        onRegisterPressed: () {
                          // Handle registration
                        },
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
