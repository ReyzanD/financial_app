import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'text_field.dart';
import 'auth_button.dart';
import 'package:financial_app/utils/design_tokens.dart';

class LoginForm extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onLoginPressed;
  final bool isLoading;

  const LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onLoginPressed,
    this.isLoading = false,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        key: const ValueKey('login-form'),
        children: [
          // Username Field
          CustomTextField(
            controller: widget.emailController,
            label: 'Email',
            icon: Icons.person_outline_rounded,
            isPassword: false,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 20),

          // Password Field
          CustomTextField(
            controller: widget.passwordController,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            obscureText: widget.obscurePassword,
            onToggleObscure: widget.onToggleObscure,
            autofillHints: const [AutofillHints.password],
          ),
        const SizedBox(height: 15),

        // Forgot Password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              // Handle forgot password
            },
            child: Text(
              'Forgot Password ?',
              style: GoogleFonts.poppins(
                color: DesignTokens.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Sign In Button
        AuthButton(
          text: 'Sign In',
          onPressed: widget.onLoginPressed,
          isLoading: widget.isLoading,
        ),
      ],
      ),
    );
  }
}

class RegisterForm extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onRegisterPressed;
  final bool isLoading;

  const RegisterForm({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onRegisterPressed,
    this.isLoading = false,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        key: const ValueKey('register-form'),
        children: [
          // Name Field
          CustomTextField(
            controller: widget.nameController,
            label: 'Name',
            icon: Icons.person_add_outlined,
            isPassword: false,
            autofillHints: const [AutofillHints.name],
          ),
          const SizedBox(height: 20),

          // Email Field
          CustomTextField(
            controller: widget.emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            isPassword: false,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 20),

          // Password Field
          CustomTextField(
            controller: widget.passwordController,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            obscureText: widget.obscurePassword,
            onToggleObscure: widget.onToggleObscure,
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: 30),

          // Sign Up Button
          AuthButton(
            text: 'Sign Up',
            onPressed: widget.onRegisterPressed,
            isLoading: widget.isLoading,
          ),
        ],
      ),
    );
  }
}
