import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnalyticsHeader extends StatelessWidget {
  const AnalyticsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analisis Keuangan',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lihat pola dan tren pengeluaran Anda',
            style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
