import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/location_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class LocationInsightCard extends StatefulWidget {
  final String transactionId;
  final LatLng? transactionLocation;

  const LocationInsightCard({
    super.key,
    required this.transactionId,
    this.transactionLocation,
  });

  @override
  State<LocationInsightCard> createState() => _LocationInsightCardState();
}

class _LocationInsightCardState extends State<LocationInsightCard> {
  Position? _currentLocation;
  double? _distance;
  String _locationString = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadLocationData();
  }

  Future<void> _loadLocationData() async {
    // Get current location
    _currentLocation = await LocationService.getCurrentLatLng();

    // Calculate distance if transaction location is available
    if (widget.transactionLocation != null && _currentLocation != null) {
      _distance =
          LocationService.calculateDistance(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            widget.transactionLocation!.latitude,
            widget.transactionLocation!.longitude,
          ) /
          1000; // Convert meters to kilometers
    }

    // Get location string
    if (widget.transactionLocation != null) {
      _locationString = LocationService.getAddressFromCoordinates(
        widget.transactionLocation!.latitude,
        widget.transactionLocation!.longitude,
      );
    } else {
      _locationString = 'Location not available';
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.location, color: Color(0xFF8B5FBF), size: 20),
              const SizedBox(width: 8),
              Text(
                'Location Insight',
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
            'Transaction Location: $_locationString',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),
          if (_distance != null) ...[
            const SizedBox(height: 8),
            Text(
              'Distance from current location: ${_distance!.toStringAsFixed(1)} km',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black26,
            ),
            child:
                widget.transactionLocation != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: widget.transactionLocation!,
                          initialZoom: 15.0,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.financial_app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: widget.transactionLocation!,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                    : Center(
                      child: Text(
                        'Map not available',
                        style: GoogleFonts.poppins(color: Colors.white54),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
