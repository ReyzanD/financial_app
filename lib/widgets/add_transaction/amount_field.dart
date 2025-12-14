import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          borderSide: const BorderSide(color: Color(0xFF8B5FBF)),
        ),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Masukkan jumlah transaksi';
        }

        // Remove non-numeric characters for validation
        final cleanValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
        final amount = double.tryParse(cleanValue);

        if (amount == null) {
          return 'Masukkan jumlah yang valid';
        }

        if (amount <= 0) {
          return 'Jumlah harus lebih dari 0';
        }

        // Max limit: 999,999,999,999 (999 triliun)
        const maxAmount = 999999999999.0;
        if (amount > maxAmount) {
          return 'Jumlah maksimal adalah Rp 999,999,999,999';
        }

        return null;
      },
    );
  }
}
