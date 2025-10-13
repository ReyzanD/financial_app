import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/utils/formatters.dart';

class AIRecommendations extends StatelessWidget {
  const AIRecommendations({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF8B5FBF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.flash, color: Color(0xFF8B5FBF), size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Recommendations',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Berdasarkan pola spending Anda, coba kurangi '
            'pengeluaran di kategori Makanan dengan memasak '
            'lebih sering di rumah.',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            'Potensi penghematan: ${CurrencyFormatter.formatRupiah(300000)}/bulan',
            style: GoogleFonts.poppins(
              color: Color(0xFF8B5FBF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
