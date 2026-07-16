import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:financial_app/services/location_service.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/utils/design_tokens.dart';

class MapScreenController extends ChangeNotifier {
  final TransactionDataService _transactionData;

  MapScreenController({required TransactionDataService transactionData})
    : _transactionData = transactionData;

  final MapController mapController = MapController();
  LatLng? _currentPosition;
  final List<Marker> _markers = [];
  bool _isLoading = false;
  String? _error;

  LatLng? get currentPosition => _currentPosition;
  List<Marker> get markers => _markers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final pos = await LocationService.getCurrentPosition();
      if (pos != null) {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
        await _loadMapData();
      } else {
        _error = 'Lokasi tidak tersedia';
      }
    } catch (e) {
      LoggerService.error('Error initializing map', error: e);
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadMapData() async {
    if (_currentPosition == null) return;
    try {
      final data = await _transactionData.getTransactions(limit: 100);
      _markers.clear();
      for (final item in data['transactions'] as List<dynamic>? ?? []) {
        final loc =
            item is Map<String, dynamic>
                ? (item['location_data'] as Map<String, dynamic>?)
                : null;
        if (loc != null && loc['lat'] != null && loc['lng'] != null) {
          _markers.add(
            Marker(
              point: LatLng(
                (loc['lat'] as num).toDouble(),
                (loc['lng'] as num).toDouble(),
              ),
              child: const Icon(
                Iconsax.location,
                color: DesignTokens.primaryColor,
                size: 32,
              ),
            ),
          );
        }
      }
    } catch (e) {
      LoggerService.error('Error loading map data', error: e);
    }
  }
}
