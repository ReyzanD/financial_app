import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/utils/design_tokens.dart';

class AdditionalOptions extends StatelessWidget {
  final bool isRecurring;
  final ValueChanged<bool> onChanged;

  const AdditionalOptions({
    super.key,
    required this.isRecurring,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opsi Tambahan',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Switch(
              value: isRecurring,
              onChanged: onChanged,
              activeThumbColor: DesignTokens.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Transaksi Berulang',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }
}
