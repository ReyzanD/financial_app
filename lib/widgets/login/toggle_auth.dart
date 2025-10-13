import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ToggleAuth extends StatelessWidget {
  final bool isLogin;
  final VoidCallback onToggle;

  const ToggleAuth({super.key, required this.isLogin, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isLogin ? "Don't have an account ?" : "Already have an account ?",
          style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onToggle,
          child: Text(
            isLogin ? 'Register Now >' : 'Log in >',
            style: GoogleFonts.poppins(
              color: const Color(0xFF8B5FBF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
