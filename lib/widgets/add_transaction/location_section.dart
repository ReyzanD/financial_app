import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/models/location_data.dart';
import 'package:financial_app/utils/design_tokens.dart';

class LocationSection extends StatelessWidget {
  final LocationData? currentLocation;
  final bool isGettingLocation;
  final VoidCallback onGetLocation;
  final VoidCallback onPickFromMap;
  final VoidCallback onClearLocation;

  const LocationSection({
    super.key,
    required this.currentLocation,
    required this.isGettingLocation,
    required this.onGetLocation,
    required this.onPickFromMap,
    required this.onClearLocation,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n?.location ?? 'Lokasi',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            if (isGettingLocation)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: DesignTokens.primaryColor),
              ),
          ],
        ),
        const SizedBox(height: DesignTokens.spacing3),
        if (currentLocation != null) _buildLocationInfo(l10n) else _buildLocationButton(l10n),
      ],
    );
  }

  Widget _buildLocationButton(AppLocalizations? l10n) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isGettingLocation ? null : onGetLocation,
            icon:
                isGettingLocation
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: DesignTokens.primaryColor),
                    )
                    : const Icon(Iconsax.location, size: 16),
            label: Text(
              isGettingLocation ? (l10n?.detecting ?? 'Mendeteksi...') : (l10n?.current_location ?? 'Lokasi Saat Ini'),
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: DesignTokens.primaryColor,
              side: const BorderSide(color: DesignTokens.primaryColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isGettingLocation ? null : onPickFromMap,
            icon: const Icon(Iconsax.map, size: 16),
            label: Text('Pilih dari Peta', style: GoogleFonts.poppins(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo(AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: Color.lerp(Colors.green, Colors.transparent, 0.3)!, width: 0.3),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.location, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentLocation!.placeName ?? (l10n?.location_detected ?? 'Lokasi Terdeteksi'),
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                if (currentLocation!.address != null) ...[
                  const SizedBox(height: DesignTokens.spacing1),
                  Text(
                    currentLocation!.address!,
                    style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: DesignTokens.spacing1),
                Text(
                  'Lat: ${currentLocation!.latitude.toStringAsFixed(4)}, Lng: ${currentLocation!.longitude.toStringAsFixed(4)}',
                  style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 10),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Iconsax.edit, size: 18, color: DesignTokens.primaryColor),
                onPressed: onPickFromMap,
                tooltip: l10n?.edit_on_map ?? 'Edit di peta',
              ),
              IconButton(
                icon: Icon(Iconsax.close_circle, size: 18, color: Colors.grey[500]),
                onPressed: onClearLocation,
                tooltip: l10n?.delete_location ?? 'Hapus lokasi',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
