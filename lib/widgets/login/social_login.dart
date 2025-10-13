import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SocialLogin extends StatelessWidget {
  const SocialLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Or Continue with',
          style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialIcon(Icons.g_mobiledata_rounded),
            const SizedBox(width: 20),
            _buildSocialIcon(Icons.apple_rounded),
            const SizedBox(width: 20),
            _buildSocialIcon(Icons.facebook_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Icon(icon, color: Colors.grey[400], size: 24),
    );
  }
}
