import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/utils/form_validators.dart';
import 'package:financial_app/utils/design_tokens.dart';

class NotesField extends StatelessWidget {
  final TextEditingController controller;

  const NotesField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: controller,
      maxLines: 3,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: l10n?.notes_optional ?? 'Catatan (Opsional)',
        labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
        hintText:
            l10n?.add_notes_hint ?? 'Tambahkan catatan atau detail tambahan...',
        hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          borderSide: const BorderSide(color: DesignTokens.primaryColor),
        ),
        filled: true,
        fillColor: DesignTokens.surfaceDark,
      ),
      maxLength: FormValidators.maxNotesLength,
      validator: (value) => FormValidators.validateNotes(value),
    );
  }
}
