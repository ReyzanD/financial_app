import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:financial_app/services/location_service.dart';
import 'package:financial_app/services/map_provider_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/data/place_visit_data_service.dart';
import 'package:financial_app/services/data/alternative_suggestion_data_service.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';
import 'package:financial_app/services/overpass_api_service.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/core/di/service_locator.dart';

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
  bool _showAlternatives = false;
  bool _isLoadingAlternatives = false;
  String? _errorMessage;
  final TransactionDataService _transactionDataService =
      getIt<TransactionDataService>();
  final OverpassApiService _overpassApiService =
      getIt<OverpassApiService>();
  final PlaceVisitDataService _placeVisitDataService =
      getIt<PlaceVisitDataService>();
  final AlternativeSuggestionDataService _alternativeDataService =
      getIt<AlternativeSuggestionDataService>();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadTransactionMarkers();
  }

  Future<void> _toggleAlternatives() async {
    setState(() => _showAlternatives = !_showAlternatives);

    if (_showAlternatives) {
      await _loadAlternativeMarkers();
    } else {
      // Remove alternative markers (keep transaction markers + user location)
      setState(() {
        _markers.removeWhere(
          (m) => _isAlternativeMarker(m),
        );
      });
    }
  }

  bool _isAlternativeMarker(Marker m) {
    // Alternative markers have width 36 (distinct from 45/80 transaction/pin)
    return m.width == 36;
  }

  Future<void> _loadAlternativeMarkers() async {
    setState(() => _isLoadingAlternatives = true);
    try {
      final placeVisits = await _placeVisitDataService.getPlaceVisits();
      int totalMarkers = 0;

      for (final pv in placeVisits.take(10)) {
        // Check cached suggestions first
        final cached = await _alternativeDataService.getForOriginPlace(pv.id);

        List<_SuggestionPoint> points;
        if (cached.isNotEmpty) {
          points = cached
              .map((s) => _SuggestionPoint(
                    name: s.suggestedPlaceName,
                    lat: s.suggestedLatitude,
                    lng: s.suggestedLongitude,
                    distance: s.distanceMeters,
                    savings: s.estimatedSavings,
                    confidence: s.confidenceLevel,
                  ))
              .toList();
        } else {
          // Query Overpass on-the-fly
          try {
            final pois = await _overpassApiService.findNearbyPois(
              latitude: pv.latitude,
              longitude: pv.longitude,
              categoryName: pv.category,
              radiusMeters: 1000,
              maxResults: 5,
            );
            points = pois
                .map((poi) => _SuggestionPoint(
                      name: poi.name,
                      lat: poi.latitude,
                      lng: poi.longitude,
                      distance: LocationService.calculateDistance(
                        pv.latitude, pv.longitude, poi.latitude, poi.longitude,
                      ),
                    ))
                .toList();
          } catch (_) {
            continue;
          }
        }

        for (final pt in points) {
          _addAlternativeMarker(pt);
          totalMarkers++;
        }
      }

      if (mounted) {
        ErrorHandlerService.showInfoSnackbar(
          context,
          '$totalMarkers tempat alternatif ditampilkan',
        );
      }
    } catch (e) {
      LoggerService.error('Error loading alternative markers', error: e);
    } finally {
      if (mounted) setState(() => _isLoadingAlternatives = false);
    }
  }

  void _addAlternativeMarker(_SuggestionPoint pt) {
    setState(() {
      _markers.add(
        Marker(
          point: LatLng(pt.lat, pt.lng),
          width: 36,
          height: 36,
          child: GestureDetector(
            onTap: () => _showAlternativeInfo(pt),
            child: Container(
              decoration: BoxDecoration(
                color: DesignTokens.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Iconsax.shop,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      );
    });
  }

  void _showAlternativeInfo(_SuggestionPoint pt) {
    final distanceText = pt.distance != null
        ? pt.distance! < 1000
            ? '${pt.distance!.round()} m'
            : '${(pt.distance! / 1000).toStringAsFixed(1)} km'
        : '?';
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: DesignTokens.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        ),
        title: Row(
          children: [
            Icon(Iconsax.shop, color: DesignTokens.primaryColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                pt.name,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
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
            _buildInfoRow('Jarak', distanceText, Colors.grey),
            if (pt.confidence != null)
              _buildInfoRow(
                'Confidence', '${pt.confidence}%', DesignTokens.successColor,
              ),
            if (pt.savings != null && pt.savings! > 0)
              _buildInfoRow(
                'Estimasi Hemat',
                'Rp ${pt.savings!.toStringAsFixed(0)}',
                DesignTokens.successColor,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(
              'Tutup',
              style: GoogleFonts.poppins(color: DesignTokens.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13)),
          Text(value,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Future<void> _initializeLocation() async {
    final l10n = AppLocalizations.of(context);
    try {
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
                onTap:
                    () => _showMarkerInfo(
                      l10n?.your_location ?? 'Your Location',
                      l10n?.current_position ?? 'Current position',
                    ),
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
        setState(() => _isLoading = false);
        _showLocationError();
      }
    } catch (e) {
      LoggerService.error('Error initializing location', error: e);
      setState(() {
        _errorMessage = ErrorHandlerService.getUserFriendlyMessage(e);
        _isLoading = false;
      });
    }
  }

  void _showLocationError() {
    final l10n = AppLocalizations.of(context);
    ErrorHandlerService.showErrorSnackbar(
      context,
      l10n?.unable_to_get_location_permission ??
          'Unable to get current location. Please check permissions.',
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              l10n?.failed_to_load_data ?? 'Gagal Memuat Data',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _markers.clear();
                  _isLoading = true;
                });
                _initializeLocation();
                _loadTransactionMarkers();
              },
              icon: const Icon(Icons.refresh),
              label: Text(l10n?.try_again ?? 'Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadTransactionMarkers() async {
    final l10n = AppLocalizations.of(context);
    try {
      final transactionsData =
          await _transactionDataService.getTransactions(limit: 100);
      final transactions = List<Map<String, dynamic>>.from(
        transactionsData['transactions'] ?? [],
      );
      for (var tx in transactions) {
        final lat = (tx['latitude_232143'] as num?)?.toDouble();
        final lng = (tx['longitude_232143'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          _addTransactionMarker(
            LatLng(lat, lng),
            tx['description_232143']?.toString() ??
                (l10n?.transaction ?? 'Transaksi'),
            tx['type_232143']?.toString() ?? 'expense',
            (tx['amount_232143'] ?? 0).toDouble(),
            tx['transaction_date_232143']?.toString() ?? '',
          );
        }
      }
      if (mounted)
        ErrorHandlerService.showInfoSnackbar(
          context,
          l10n?.transaction_locations_shown(_markers.length - 1) ??
              '${_markers.length - 1} lokasi transaksi ditampilkan',
        );
    } catch (e) {
      LoggerService.error('Error loading transaction markers', error: e);
      if (mounted) setState(() => _isLoading = false);
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
            onTap:
                () =>
                    _showTransactionMarkerInfo(description, type, amount, date),
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
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder:
          (c) => AlertDialog(
            backgroundColor: DesignTokens.surfaceDark,
            title: Text(title, style: GoogleFonts.poppins(color: Colors.white)),
            content: Text(
              subtitle,
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(
                  l10n?.close ?? 'Tutup',
                  style: GoogleFonts.poppins(color: DesignTokens.primaryColor),
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
    final l10n = AppLocalizations.of(context);
    final typeLabel =
        type == 'income'
            ? (l10n?.income ?? 'Pemasukan')
            : type == 'expense'
            ? (l10n?.expense ?? 'Pengeluaran')
            : (l10n?.transfer ?? 'Transfer');
    final color = _getMarkerColor(type);
    showDialog(
      context: context,
      builder:
          (c) => AlertDialog(
            backgroundColor: DesignTokens.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
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
                _buildInfoRow(l10n?.type ?? 'Tipe', typeLabel, color),
                const SizedBox(height: 12),
                _buildInfoRow(
                  l10n?.amount ?? 'Jumlah',
                  'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                  color,
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    l10n?.date ?? 'Tanggal',
                    date.split('T')[0],
                    Colors.grey,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(
                  l10n?.close ?? 'Tutup',
                  style: GoogleFonts.poppins(color: DesignTokens.primaryColor),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: DesignTokens.backgroundDark,
        title: Text(
          l10n?.transaction_map ?? 'Peta Transaksi',
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
          if (_isLoadingAlternatives)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(
                _showAlternatives
                    ? Iconsax.shop
                    : Iconsax.shop_add,
                color: _showAlternatives
                    ? DesignTokens.primaryColor
                    : Colors.white,
              ),
              onPressed: _toggleAlternatives,
              tooltip: _showAlternatives
                  ? 'Sembunyikan alternatif'
                  : 'Tampilkan alternatif',
            ),
          IconButton(
            icon: const Icon(Iconsax.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _markers.clear());
              _initializeLocation();
              _loadTransactionMarkers();
            },
            tooltip: l10n?.reload_tooltip ?? 'Muat ulang',
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? _buildErrorState()
                    : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter:
                            _currentPosition ?? const LatLng(-5.1477, 119.4327),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'map_fab',
        onPressed: () async {
          final pos = await LocationService.getCurrentLatLng();
          if (pos != null)
            _mapController.move(LatLng(pos.latitude, pos.longitude), 18.0);
        },
        backgroundColor: DesignTokens.primaryColor,
        child: const Icon(Iconsax.gps, color: Colors.white),
      ),
    );
  }
}

/// Internal helper for alternative place marker data.
class _SuggestionPoint {
  final String name;
  final double lat;
  final double lng;
  final double? distance;
  final double? savings;
  final int? confidence;

  _SuggestionPoint({
    required this.name,
    required this.lat,
    required this.lng,
    this.distance,
    this.savings,
    this.confidence,
  });
}
