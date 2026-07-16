import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/utils/design_tokens.dart';

class SocialLogin extends StatelessWidget {
  const SocialLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Or Continue with', style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12)),
        const SizedBox(height: DesignTokens.spacing5),
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
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: DesignTokens.borderDark, width: 1),
      ),
      child: Icon(icon, color: Colors.grey[400], size: 24),
    );
  }
}
