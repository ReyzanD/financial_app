import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/utils/design_tokens.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final List<String>? autofillHints;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.isPassword,
    this.obscureText = false,
    this.onToggleObscure,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      autofillHints: autofillHints,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
        hintStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16),
        prefixIcon: Icon(icon, color: Colors.grey[400]),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey[400]),
                  onPressed: onToggleObscure,
                )
                : null,
        filled: true,
        fillColor: DesignTokens.borderDark, // Dark gray background
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          borderSide: const BorderSide(
            color: DesignTokens.primaryColor, // Purple accent when focused
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}
