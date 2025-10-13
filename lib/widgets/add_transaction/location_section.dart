import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/models/location_data.dart';

class LocationSection extends StatelessWidget {
  final LocationData? currentLocation;
  final bool isGettingLocation;
  final VoidCallback onGetLocation;

  const LocationSection({
    super.key,
    required this.currentLocation,
    required this.isGettingLocation,
    required this.onGetLocation,
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
    return OutlinedButton.icon(
      onPressed: isGettingLocation ? null : onGetLocation,
      icon:
          isGettingLocation
              ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: const Color(0xFF8B5FBF),
                ),
              )
              : const Icon(Iconsax.location, size: 16),
      label: Text(
        isGettingLocation ? 'Mendeteksi Lokasi...' : 'Ambil Lokasi Saat Ini',
        style: GoogleFonts.poppins(fontSize: 12),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF8B5FBF),
        side: BorderSide(color: const Color(0xFF8B5FBF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
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
          Icon(Iconsax.location, color: Colors.green, size: 20),
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
                  'Lokasi akan digunakan untuk analisis harga',
                  style: GoogleFonts.poppins(color: Colors.green, fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Iconsax.close_circle, size: 20, color: Colors.grey[500]),
            onPressed: () {
              // TODO: Implement clear location
            },
          ),
        ],
      ),
    );
  }
}
