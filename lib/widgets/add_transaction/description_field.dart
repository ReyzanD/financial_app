import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/utils/form_validators.dart';
import 'package:financial_app/utils/design_tokens.dart';

class DescriptionField extends StatelessWidget {
  final TextEditingController controller;

  const DescriptionField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: controller,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: l10n?.description ?? 'Deskripsi',
        labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
        hintText: l10n?.description_hint ?? 'Contoh: Makan siang, Belanja bulanan, dll.',
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
      maxLength: FormValidators.maxDescriptionLength,
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text('$currentLength / $maxLength', style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12)),
        );
      },
      validator: (value) => FormValidators.validateDescription(value),
    );
  }
}
