import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:financial_app/services/location_service.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/map_provider_service.dart';
import 'package:financial_app/services/logger_service.dart';
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
      final transactionsData = await _apiService.getTransactions(limit: 100);
      final transactions = List<dynamic>.from(
        transactionsData['transactions'] ?? [],
      );

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

          final type = transaction['type']?.toString() ?? 'expense';
          final amount = transaction['amount'] ?? 0;
          final description = transaction['description'] ?? 'Transaksi';
          final date = transaction['date']?.toString() ?? '';

          _addTransactionMarker(
            LatLng(lat, lng),
            description,
            type,
            amount.toDouble(),
            date,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_markers.length - 1} lokasi transaksi ditampilkan',
            ),
            backgroundColor: const Color(0xFF8B5FBF),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      LoggerService.error('Error loading transaction markers', error: e);
    }
  }

  Color _getMarkerColor(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return Colors.green;
      case 'expense':
        return Colors.red;
      case 'transfer':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  IconData _getMarkerIcon(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return Icons.add_circle;
      case 'expense':
        return Icons.remove_circle;
      case 'transfer':
        return Icons.swap_horiz;
      default:
        return Icons.location_on;
    }
  }

  void _addTransactionMarker(
    LatLng position,
    String description,
    String type,
    double amount,
    String date,
  ) {
    final color = _getMarkerColor(type);
    final icon = _getMarkerIcon(type);

    setState(() {
      _markers.add(
        Marker(
          point: position,
          width: 45,
          height: 45,
          child: GestureDetector(
            onTap: () {
              _showTransactionMarkerInfo(description, type, amount, date);
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.location_on, color: color, size: 45),
                Positioned(
                  top: 8,
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
              ],
            ),
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
                  'Tutup',
                  style: GoogleFonts.poppins(color: const Color(0xFF8B5FBF)),
                ),
              ),
            ],
          ),
    );
  }

  void _showTransactionMarkerInfo(
    String description,
    String type,
    double amount,
    String date,
  ) {
    final typeLabel =
        type == 'income'
            ? 'Pemasukan'
            : type == 'expense'
            ? 'Pengeluaran'
            : 'Transfer';
    final color = _getMarkerColor(type);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(_getMarkerIcon(type), color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    description,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Tipe', typeLabel, color),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Jumlah',
                  'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                  color,
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow('Tanggal', date.split('T')[0], Colors.grey),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Tutup',
                  style: GoogleFonts.poppins(color: const Color(0xFF8B5FBF)),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Peta Transaksi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _markers.clear();
              });
              _initializeLocation();
              _loadTransactionMarkers();
            },
            tooltip: 'Muat ulang',
          ),
        ],
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
                        -5.1477,
                        119.4327,
                      ), // Makassar, Sulawesi Selatan
                  initialZoom: 15.0,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapProviderService.getTileUrlTemplate(),
                    userAgentPackageName: 'com.example.financial_app',
                  ),
                  MarkerLayer(markers: _markers),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'map_fab',
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
