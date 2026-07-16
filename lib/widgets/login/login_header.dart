import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/utils/design_tokens.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('login-header'),
      children: [
        // Icon/Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [DesignTokens.primaryColor, DesignTokens.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color.lerp(Colors.transparent, DesignTokens.primaryColor, 0.3)!.withAlpha(255),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: DesignTokens.spacing5),
        Text(
          'Hello Again!',
          style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: DesignTokens.spacing2),
        Text('Welcome back to your financial hub', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400])),
      ],
    );
  }
}

class RegisterHeader extends StatelessWidget {
  const RegisterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('register-header'),
      children: [
        // Animated Logo
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [DesignTokens.secondaryColor, DesignTokens.primaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color.lerp(Colors.transparent, DesignTokens.secondaryColor, 0.4)!.withAlpha(255),
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: DesignTokens.spacing5),
        Text('Get Started', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: DesignTokens.spacing2),
        Text('Create your financial journey', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400])),
      ],
    );
  }
}
