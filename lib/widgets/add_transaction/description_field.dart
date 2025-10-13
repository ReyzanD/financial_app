import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DescriptionField extends StatelessWidget {
  final TextEditingController controller;

  const DescriptionField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Deskripsi',
        labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
        hintText: 'Contoh: Makan siang, Belanja bulanan, dll.',
        hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
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
          return 'Masukkan deskripsi transaksi';
        }
        return null;
      },
    );
  }
}
