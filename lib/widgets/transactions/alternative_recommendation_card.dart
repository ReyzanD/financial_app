import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/models/location_recommendation.dart';

class AlternativeRecommendationCard extends StatelessWidget {
  final LocationRecommendation recommendation;

  const AlternativeRecommendationCard({
    super.key,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                recommendation.type == RecommendationType.price_alert
                    ? Iconsax.discount_shape
                    : Iconsax.location,
                color: const Color(0xFF8B5FBF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation.title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.description,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Iconsax.location, color: Colors.grey[500], size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      recommendation.metadata?['location'] as String? ??
                          'Lokasi tidak diketahui',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Iconsax.map, color: Colors.grey[500], size: 14),
                  const SizedBox(width: 4),
                  Text(
                    recommendation.metadata?['distance'] as String? ??
                        'Jarak tidak diketahui',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (recommendation.estimatedSavings > 0)
                    Text(
                      'Hemat ${CurrencyFormatter.formatRupiah(recommendation.estimatedSavings)}',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF8B5FBF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    const SizedBox(),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement navigation to maps or external app
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Navigasi ke ${recommendation.metadata?['location'] ?? 'lokasi'}',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFF8B5FBF),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5FBF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      textStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: const Text('Kunjungi'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
