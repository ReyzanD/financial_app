import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:financial_app/services/location_service.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  final List<Marker> _markers = [];
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadTransactionMarkers();
  }

  Future<void> _initializeLocation() async {
    final position = await LocationService.getCurrentLatLng();
    if (position != null) {
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = latLng;
        _markers.add(
          Marker(
            point: latLng,
            width: 80,
            height: 80,
            child: GestureDetector(
              onTap: () {
                _showMarkerInfo('Your Location', 'Current position');
              },
              child: const Icon(
                Icons.location_on,
                color: Colors.blue,
                size: 40,
              ),
            ),
          ),
        );
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      _showLocationError();
    }
  }

  void _showLocationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to get current location. Please check permissions.',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _loadTransactionMarkers() async {
    try {
      final transactions = await _apiService.getTransactions();

      for (var transaction in transactions) {
        final location = transaction['location'];
        if (location != null &&
            location['latitude'] != null &&
            location['longitude'] != null) {
          final lat =
              location['latitude'] is String
                  ? double.parse(location['latitude'])
                  : location['latitude'].toDouble();
          final lng =
              location['longitude'] is String
                  ? double.parse(location['longitude'])
                  : location['longitude'].toDouble();

          _addTransactionMarker(
            LatLng(lat, lng),
            transaction['description'] ?? 'Transaction',
            '${transaction['type']}: Rp ${transaction['amount']?.toStringAsFixed(0)}',
          );
        }
      }
    } catch (e) {
      print('Error loading transaction markers: $e');
    }
  }

  void _addTransactionMarker(LatLng position, String title, String snippet) {
    setState(() {
      _markers.add(
        Marker(
          point: position,
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () {
              _showMarkerInfo(title, snippet);
            },
            child: const Icon(Icons.location_on, color: Colors.red, size: 40),
          ),
        ),
      );
    });
  }

  void _showMarkerInfo(String title, String subtitle) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(title, style: GoogleFonts.poppins(color: Colors.white)),
            content: Text(
              subtitle,
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(color: const Color(0xFF8B5FBF)),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Location Map',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter:
                      _currentPosition ??
                      const LatLng(
                        -6.2088,
                        106.8456,
                      ), // Jakarta - change if needed
                  initialZoom: 15.0,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.financial_app',
                  ),
                  MarkerLayer(markers: _markers),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final position = await LocationService.getCurrentLatLng();
          if (position != null) {
            final latLng = LatLng(position.latitude, position.longitude);
            _mapController.move(latLng, 18.0);
          }
        },
        backgroundColor: const Color(0xFF8B5FBF),
        child: const Icon(Iconsax.gps, color: Colors.white),
      ),
    );
  }
}
