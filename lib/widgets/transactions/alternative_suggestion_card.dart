import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:financial_app/models/alternative_suggestion.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'dart:io' show Platform;

/// Displays a single alternative place suggestion with distance, price savings,
/// and a "Navigate" button.
class AlternativeSuggestionCard extends StatelessWidget {
  final AlternativeSuggestion suggestion;
  final bool isCompact;

  const AlternativeSuggestionCard({
    super.key,
    required this.suggestion,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasSavings =
        suggestion.estimatedSavings != null && suggestion.estimatedSavings! > 0;
    final distanceText = _formatDistance(suggestion.distanceMeters);
    final confidenceColor = _confidenceColor(suggestion.confidenceLevel);
    final savingsText =
        hasSavings
            ? 'Hemat ${CurrencyFormatter.formatRupiah(suggestion.estimatedSavings!)}'
            : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isCompact ? 12 : DesignTokens.spacing4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(color: DesignTokens.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                hasSavings ? Iconsax.discount_shape : Iconsax.location,
                color: DesignTokens.primaryColor,
                size: isCompact ? 18 : 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  suggestion.suggestedPlaceName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasSavings)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.successColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    savingsText!,
                    style: GoogleFonts.poppins(
                      color: DesignTokens.successColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isCompact ? 6 : 10),
          Row(
            children: [
              _infoChip(Iconsax.location, distanceText),
              const SizedBox(width: 8),
              _infoChip(Iconsax.shield_tick, '${suggestion.confidenceLevel}%'),
              if (suggestion.basis == 'price' && !hasSavings)
                const SizedBox(width: 8),
              if (suggestion.basis == 'price' && !hasSavings)
                _infoChip(Iconsax.dollar_square, 'Price'),
            ],
          ),
          SizedBox(height: isCompact ? 6 : 10),
          Row(
            children: [
              // Confidence indicator bar
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: suggestion.confidenceLevel / 100.0,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(confidenceColor),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 32,
                child: ElevatedButton.icon(
                  onPressed: () => _openInMaps(context),
                  icon: const Icon(Iconsax.map, size: 14),
                  label: Text(
                    AppLocalizations.of(context)?.visit ?? 'Lihat',
                    style: GoogleFonts.poppins(fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.grey[500], size: 12),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 11),
        ),
      ],
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Color _confidenceColor(int level) {
    if (level >= 70) return DesignTokens.successColor;
    if (level >= 40) return Colors.orange;
    return Colors.grey;
  }

  Future<void> _openInMaps(BuildContext context) async {
    try {
      final lat = suggestion.suggestedLatitude;
      final lng = suggestion.suggestedLongitude;
      final name = suggestion.suggestedPlaceName;

      final uri = Uri.parse(
        Platform.isAndroid
            ? 'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
            : Platform.isIOS
            ? 'https://maps.apple.com/?ll=$lat,$lng&q=$name'
            : 'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ErrorHandlerService.showInfoSnackbar(
          context,
          'Membuka navigasi ke $name',
        );
      }
    } catch (e) {
      ErrorHandlerService.showErrorSnackbar(
        context,
        'Tidak dapat membuka navigasi',
      );
    }
  }
}
