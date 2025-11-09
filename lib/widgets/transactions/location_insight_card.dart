import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/location_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  LatLng? _currentLocation;
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
      _distance = LocationService.calculateDistance(
        _currentLocation!,
        widget.transactionLocation!,
      );
    }

    // Get location string
    if (widget.transactionLocation != null) {
      _locationString = await LocationService.getAddressFromLatLng(
        widget.transactionLocation!,
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
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: widget.transactionLocation!,
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('transaction_location'),
                            position: widget.transactionLocation!,
                            infoWindow: const InfoWindow(
                              title: 'Transaction Location',
                            ),
                          ),
                        },
                        zoomControlsEnabled: false,
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
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
