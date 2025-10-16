import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotesField extends StatelessWidget {
  final TextEditingController controller;

  const NotesField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Catatan (Opsional)',
        labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
        hintText: 'Tambahkan catatan atau detail tambahan...',
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
    );
  }
}
