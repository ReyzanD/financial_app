import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final Color? fillColor;
  final Color? textColor;
  final Color? labelColor;
  final double? fontSize;
  final FontWeight? fontWeight;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.isPassword,
    this.obscureText = false,
    this.onToggleObscure,
    this.fillColor,
    this.textColor,
    this.labelColor,
    this.fontSize,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:
            fillColor ??
            const Color(
              0xFF1A1A1A,
            ), // Use fillColor if provided, else default dark
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
        // Optional: Add a subtle shadow for extra visibility
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: GoogleFonts.poppins(
          color:
              textColor ??
              Colors.white, // Use textColor if provided, else white
          fontSize: fontSize ?? 14,
          fontWeight: fontWeight ?? FontWeight.normal,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color:
                labelColor ??
                Colors.grey[500], // Use labelColor if provided, else grey
          ),
          prefixIcon: Icon(
            icon,
            color: labelColor ?? Colors.grey[500],
          ), // Match label color
          suffixIcon:
              isPassword
                  ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color:
                          labelColor ?? Colors.grey[500], // Match label color
                    ),
                    onPressed: onToggleObscure,
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
