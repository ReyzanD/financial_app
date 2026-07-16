import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/models/location_recommendation.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'dart:io' show Platform;

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
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(color: DesignTokens.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                recommendation.type == RecommendationType.priceAlert
                    ? Iconsax.discount_shape
                    : Iconsax.location,
                color: DesignTokens.primaryColor,
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
          const SizedBox(height: DesignTokens.spacing2),
          Text(
            recommendation.description,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: DesignTokens.spacing3),
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
              const SizedBox(height: DesignTokens.spacing2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (recommendation.estimatedSavings > 0)
                    Text(
                      'Hemat ${CurrencyFormatter.formatRupiah(recommendation.estimatedSavings)}',
                      style: GoogleFonts.poppins(
                        color: DesignTokens.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    const SizedBox(),
                  ElevatedButton(
                    onPressed: () async {
                      // Open maps with location
                      final location = recommendation.metadata?['location'];
                      if (location != null) {
                        // Try to open in Google Maps or default maps app
                        final lat = recommendation.metadata?['latitude'];
                        final lng = recommendation.metadata?['longitude'];

                        if (lat != null && lng != null) {
                          try {
                            // Build platform-appropriate maps URL
                            final uri = Uri.parse(
                              Platform.isAndroid
                                  ? 'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
                                  : Platform.isIOS
                                  ? 'https://maps.apple.com/?ll=$lat,$lng&q=${Uri.encodeComponent(location)}'
                                  : 'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng',
                            );
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              ErrorHandlerService.showInfoSnackbar(
                                context,
                                'Membuka navigasi ke $location',
                              );
                            }
                          } catch (e) {
                            ErrorHandlerService.showErrorSnackbar(
                              context,
                              'Tidak dapat membuka navigasi',
                            );
                          }
                        } else {
                          ErrorHandlerService.showWarningSnackbar(
                            context,
                            'Lokasi tidak tersedia',
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.primaryColor,
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
                    child: Text(AppLocalizations.of(context)!.visit),
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
