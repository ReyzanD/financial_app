import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/utils/form_validators.dart';
import 'package:financial_app/utils/design_tokens.dart';

class AmountField extends StatelessWidget {
  final TextEditingController controller;

  const AmountField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: 'Jumlah',
        labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
        prefixText: 'Rp ',
        prefixStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DesignTokens.primaryColor),
        ),
        filled: true,
        fillColor: DesignTokens.surfaceDark,
      ),
      validator: (value) => FormValidators.validateAmount(value),
    );
  }
}
