import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/models/location_data.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Lokasi',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            if (isGettingLocation)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: const Color(0xFF8B5FBF),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (currentLocation != null)
          _buildLocationInfo()
        else
          _buildLocationButton(),
      ],
    );
  }

  Widget _buildLocationButton() {
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF8B5FBF),
                      ),
                    )
                    : const Icon(Iconsax.location, size: 16),
            label: Text(
              isGettingLocation ? 'Mendeteksi...' : 'Lokasi Saat Ini',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8B5FBF),
              side: const BorderSide(color: Color(0xFF8B5FBF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isGettingLocation ? null : onPickFromMap,
            icon: const Icon(Iconsax.map, size: 16),
            label: Text(
              'Pilih dari Peta',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color.lerp(Colors.green, Colors.transparent, 0.3)!,
          width: 0.3,
        ),
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
                  currentLocation!.placeName ?? 'Lokasi Terdeteksi',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (currentLocation!.address != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    currentLocation!.address!,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Lat: ${currentLocation!.latitude.toStringAsFixed(4)}, Lng: ${currentLocation!.longitude.toStringAsFixed(4)}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(
                  Iconsax.edit,
                  size: 18,
                  color: Color(0xFF8B5FBF),
                ),
                onPressed: onPickFromMap,
                tooltip: 'Edit di peta',
              ),
              IconButton(
                icon: Icon(
                  Iconsax.close_circle,
                  size: 18,
                  color: Colors.grey[500],
                ),
                onPressed: onClearLocation,
                tooltip: 'Hapus lokasi',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
