import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class SpendingInsights extends StatelessWidget {
  const SpendingInsights({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5FBF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.lamp_charge,
                color: const Color(0xFF8B5FBF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AI Insights',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Pengeluaran makanan Anda 15% lebih tinggi dari bulan lalu. '
            'Coba kurangi makan di luar dan masak lebih sering di rumah.',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            'Potensi penghematan: Rp 300.000',
            style: GoogleFonts.poppins(
              color: const Color(0xFF8B5FBF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
