import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/utils/formatters.dart';

class LocationInsight {
  final int averagePrice;
  final String priceComparison;
  final String recommendation;
  final int savingsPotential;

  const LocationInsight({
    required this.averagePrice,
    required this.priceComparison,
    required this.recommendation,
    required this.savingsPotential,
  });
}

class LocationInsightCard extends StatelessWidget {
  final LocationInsight insight;

  const LocationInsightCard({super.key, required this.insight});

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
            'Harga rata-rata di area ini: ${CurrencyFormatter.formatRupiah(insight.averagePrice)}',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            insight.priceComparison,
            style: GoogleFonts.poppins(
              color: Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            insight.recommendation,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            'Potensi penghematan: ${CurrencyFormatter.formatRupiah(insight.savingsPotential)}',
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
