import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/location_service.dart';
import 'package:financial_app/services/map_provider_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/models/location_data.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';

class LocationPickerMap extends StatefulWidget {
  final LocationData? initialLocation;

  const LocationPickerMap({super.key, this.initialLocation});

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng? _selectedPosition;
  LatLng? _currentPosition;
  bool _isLoading = true;
  bool _isSearching = false;
  String? _selectedAddress;
  List<Map<String, dynamic>> _searchResults = [];
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    final l10n = AppLocalizations.of(context);
    if (query.trim().isEmpty) {
      ErrorHandlerService.showWarningSnackbar(
        context,
        l10n?.search_placeholder ?? 'Masukkan nama tempat untuk mencari',
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      LoggerService.debug('🔍 Searching for location: $query');

      // Use MapProviderService with automatic fallback
      final results = await MapProviderService.searchLocation(
        query,
        countryCode: 'id',
        limit: 5,
      );

      if (results.isNotEmpty) {
        LoggerService.success('✅ Found ${results.length} results for: $query');

        setState(() {
          _searchResults = results;
          _showResults = true;
        });

        if (!mounted) return;
        ErrorHandlerService.showSuccessSnackbar(
          context,
          l10n?.search_results_found(results.length) ??
              '${results.length} lokasi ditemukan - pilih dari daftar',
        );
      } else {
        LoggerService.warning('❌ No results found for: $query');
        setState(() {
          _searchResults = [];
          _showResults = false;
        });
        if (!mounted) return;
        ErrorHandlerService.showWarningSnackbar(
          context,
          l10n?.location_not_found(query) ?? 'Lokasi "$query" tidak ditemukan',
        );
      }
    } catch (e, stackTrace) {
      LoggerService.error(
        '❌ Search error: $e',
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      ErrorHandlerService.showErrorSnackbar(
        context,
        '${l10n?.failed_to_search ?? 'Gagal mencari'}: ${ErrorHandlerService.getUserFriendlyMessage(e)}',
      );
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _initializeMap() async {
    // Get current location
    final position = await LocationService.getCurrentLatLng();

    setState(() {
      if (position != null) {
        _currentPosition = LatLng(position.latitude, position.longitude);
      }

      // If there's an initial location, use it
      if (widget.initialLocation != null) {
        _selectedPosition = LatLng(
          widget.initialLocation!.latitude,
          widget.initialLocation!.longitude,
        );
        _selectedAddress = widget.initialLocation!.address;
      } else if (_currentPosition != null) {
        // Otherwise use current location as default
        _selectedPosition = _currentPosition;
      }

      _isLoading = false;
    });
  }

  void _onMapTap(TapPosition tapPosition, LatLng position) {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _selectedPosition = position;
      _selectedAddress = null;
    });

    ErrorHandlerService.showInfoSnackbar(
      context,
      '${l10n?.location_selected ?? 'Lokasi dipilih'}: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
    );
  }

  void _moveToCurrentLocation() async {
    final l10n = AppLocalizations.of(context);
    final position = await LocationService.getCurrentLatLng();
    if (position != null) {
      final latLng = LatLng(position.latitude, position.longitude);
      _mapController.move(latLng, 16.0);
      setState(() {
        _selectedPosition = latLng;
        _currentPosition = latLng;
        _selectedAddress = null;
      });
    } else {
      if (!mounted) return;
      ErrorHandlerService.showErrorSnackbar(
        context,
        l10n?.cannot_get_current_location ??
            'Tidak dapat mendapatkan lokasi saat ini',
      );
    }
  }

  void _confirmLocation() {
    final l10n = AppLocalizations.of(context);
    if (_selectedPosition == null) {
      ErrorHandlerService.showWarningSnackbar(
        context,
        l10n?.select_location_on_map_first ??
            'Pilih lokasi di peta terlebih dahulu',
      );
      return;
    }

    final locationData = LocationData(
      latitude: _selectedPosition!.latitude,
      longitude: _selectedPosition!.longitude,
      placeName:
          _selectedAddress ?? (l10n?.selected_location ?? 'Lokasi Terpilih'),
      address: _selectedAddress,
    );

    Navigator.pop(context, locationData);
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final l10n = AppLocalizations.of(context);
    final lat = result['lat'] as double;
    final lng = result['lng'] as double;
    final displayName = result['displayName'] as String;

    final newPosition = LatLng(lat, lng);

    setState(() {
      _selectedPosition = newPosition;
      _selectedAddress = displayName;
      _showResults = false;
      _searchResults = [];
    });

    _mapController.move(newPosition, 16.0);

    ErrorHandlerService.showSuccessSnackbar(
      context,
      l10n?.selected_prefix(displayName.split(',').first) ??
          'Dipilih: ${displayName.split(',').first}',
    );
  }

  Widget _buildQuickSearchChip(String placeName) {
    return GestureDetector(
      onTap: () {
        _searchController.text = placeName;
        _searchLocation(placeName);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: DesignTokens.primaryColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          border: Border.all(
            color: DesignTokens.primaryColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Text(
          placeName,
          style: GoogleFonts.poppins(
            color: DesignTokens.primaryColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Selected location marker (red)
    if (_selectedPosition != null) {
      markers.add(
        Marker(
          point: _selectedPosition!,
          width: 50,
          height: 50,
          child: const Icon(Icons.location_on, color: Colors.red, size: 50),
        ),
      );
    }

    // Current location marker (blue) - only if different from selected
    if (_currentPosition != null && _selectedPosition != _currentPosition) {
      markers.add(
        Marker(
          point: _currentPosition!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: const Icon(Icons.my_location, color: Colors.blue, size: 20),
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.backgroundDark,
        title: Text(
          l10n?.pick_location ?? 'Pilih Lokasi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: _confirmLocation,
            icon: const Icon(
              Iconsax.tick_circle,
              color: DesignTokens.primaryColor,
            ),
            label: Text(
              l10n?.select ?? 'Pilih',
              style: GoogleFonts.poppins(
                color: DesignTokens.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  // Map
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter:
                          _selectedPosition ??
                          _currentPosition ??
                          const LatLng(-5.1477, 119.4327), // Makassar fallback
                      initialZoom: 15.0,
                      minZoom: 5.0,
                      maxZoom: 18.0,
                      onTap: _onMapTap,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: MapProviderService.getTileUrlTemplate(),
                        userAgentPackageName: 'com.financial_app',
                      ),
                      MarkerLayer(markers: _buildMarkers()),
                    ],
                  ),

                  // Search bar at top
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.surfaceDark,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Iconsax.search_normal,
                            color: DesignTokens.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    l10n?.search_places_hint ??
                                    'Cari tempat (contoh: Pantai Losari)',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey[500],
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onSubmitted: _searchLocation,
                            ),
                          ),
                          if (_isSearching)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: DesignTokens.primaryColor,
                              ),
                            )
                          else
                            IconButton(
                              icon: const Icon(
                                Iconsax.search_normal_1,
                                size: 20,
                                color: Colors.green,
                              ),
                              onPressed:
                                  () => _searchLocation(_searchController.text),
                              tooltip: l10n?.search ?? 'Cari',
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Quick search buttons OR Search results
                  if (!_showResults)
                    Positioned(
                      top: 76,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF1A1A1A,
                          ).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n?.quick_search_label ?? 'Cepat:',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[400],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _buildQuickSearchChip('Pantai Losari'),
                                _buildQuickSearchChip('Trans Studio'),
                                _buildQuickSearchChip('Fort Rotterdam'),
                                _buildQuickSearchChip('Mall Panakkukang'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Search Results List
                  if (_showResults && _searchResults.isNotEmpty)
                    Positioned(
                      top: 76,
                      left: 16,
                      right: 16,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        decoration: BoxDecoration(
                          color: DesignTokens.surfaceDark,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xFF2A2A2A),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Iconsax.location,
                                    color: DesignTokens.primaryColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      l10n?.locations_found_title(
                                            _searchResults.length,
                                          ) ??
                                          '${_searchResults.length} Lokasi Ditemukan',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Iconsax.close_circle,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showResults = false;
                                        _searchResults = [];
                                      });
                                    },
                                    tooltip: l10n?.close ?? 'Tutup',
                                  ),
                                ],
                              ),
                            ),
                            // Results list
                            Flexible(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final result = _searchResults[index];
                                  final displayName =
                                      result['displayName'] as String;
                                  final parts = displayName.split(',');
                                  final mainName = parts.first.trim();
                                  final subName =
                                      parts.length > 1
                                          ? parts
                                              .sublist(
                                                1,
                                                parts.length > 3
                                                    ? 3
                                                    : parts.length,
                                              )
                                              .join(',')
                                              .trim()
                                          : '';

                                  return InkWell(
                                    onTap: () => _selectSearchResult(result),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.withValues(
                                              alpha: 0.1,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: DesignTokens.primaryColor.withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Iconsax.location,
                                              size: 16,
                                              color: DesignTokens.primaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  mainName,
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (subName.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    subName,
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.grey[500],
                                                      fontSize: 11,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Iconsax.arrow_right_3,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Location info at bottom
                  if (_selectedPosition != null)
                    Positioned(
                      bottom: 100,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(DesignTokens.spacing4),
                        decoration: BoxDecoration(
                          color: DesignTokens.surfaceDark,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Iconsax.location,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n?.selected_location ?? 'Lokasi Terpilih',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Lat: ${_selectedPosition!.latitude.toStringAsFixed(6)}',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Lng: ${_selectedPosition!.longitude.toStringAsFixed(6)}',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Zoom in
          FloatingActionButton.small(
            heroTag: 'location_picker_zoom_in',
            onPressed: () {
              // Get current center, default to Makassar if null
              final center =
                  _selectedPosition ??
                  _currentPosition ??
                  const LatLng(-5.1477, 119.4327);
              _mapController.move(center, 16.0);
            },
            backgroundColor: DesignTokens.primaryColor,
            child: const Icon(Iconsax.add, color: Colors.white),
          ),
          const SizedBox(height: 8),
          // Zoom out
          FloatingActionButton.small(
            heroTag: 'location_picker_zoom_out',
            onPressed: () {
              final center =
                  _selectedPosition ??
                  _currentPosition ??
                  const LatLng(-5.1477, 119.4327);
              _mapController.move(center, 14.0);
            },
            backgroundColor: DesignTokens.primaryColor,
            child: const Icon(Iconsax.minus, color: Colors.white),
          ),
          const SizedBox(height: 8),
          // Current location
          FloatingActionButton(
            heroTag: 'location_picker_current_location',
            onPressed: _moveToCurrentLocation,
            backgroundColor: DesignTokens.primaryColor,
            child: const Icon(Iconsax.gps, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
