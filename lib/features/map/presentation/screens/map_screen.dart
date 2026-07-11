import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:financial_app/services/location_service.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/map_provider_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/utils/design_tokens.dart';

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
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadTransactionMarkers();
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await LocationService.getCurrentLatLng();
      if (position != null) {
        final latLng = LatLng(position.latitude, position.longitude);
        setState(() { _currentPosition = latLng; _markers.add(Marker(point: latLng, width: 80, height: 80, child: GestureDetector(onTap: () => _showMarkerInfo('Your Location', 'Current position'), child: const Icon(Icons.location_on, color: Colors.blue, size: 40)))); _isLoading = false; });
      } else { setState(() => _isLoading = false); _showLocationError(); }
    } catch (e) {
      LoggerService.error('Error initializing location', error: e);
      setState(() { _errorMessage = ErrorHandlerService.getUserFriendlyMessage(e); _isLoading = false; });
    }
  }

  void _showLocationError() => ErrorHandlerService.showErrorSnackbar(context, 'Unable to get current location. Please check permissions.');

  Widget _buildErrorState() {
    return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[400]),
      const SizedBox(height: 16), const Text('Gagal Memuat Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
      const SizedBox(height: 8), Text(_errorMessage ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      const SizedBox(height: 24),
      ElevatedButton.icon(onPressed: () { setState(() { _errorMessage = null; _markers.clear(); _isLoading = true; }); _initializeLocation(); _loadTransactionMarkers(); }, icon: const Icon(Icons.refresh), label: const Text('Coba Lagi'), style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primaryColor)),
    ])));
  }

  Future<void> _loadTransactionMarkers() async {
    try {
      final transactionsData = await _apiService.getTransactions(limit: 100);
      final transactions = List<dynamic>.from(transactionsData['transactions'] ?? []);
      for (var tx in transactions) {
        final loc = tx['location'];
        if (loc != null && loc['latitude'] != null && loc['longitude'] != null) {
          final lat = loc['latitude'] is String ? double.parse(loc['latitude']) : loc['latitude'].toDouble();
          final lng = loc['longitude'] is String ? double.parse(loc['longitude']) : loc['longitude'].toDouble();
          _addTransactionMarker(LatLng(lat, lng), tx['description']?.toString() ?? 'Transaksi', tx['type']?.toString() ?? 'expense', (tx['amount'] ?? 0).toDouble(), tx['date']?.toString() ?? '');
        }
      }
      if (mounted) ErrorHandlerService.showInfoSnackbar(context, '${_markers.length - 1} lokasi transaksi ditampilkan');
    } catch (e) { LoggerService.error('Error loading transaction markers', error: e); if (mounted) setState(() => _isLoading = false); }
  }

  Color _getMarkerColor(String type) {
    switch (type.toLowerCase()) { case 'income': return Colors.green; case 'expense': return Colors.red; case 'transfer': return Colors.orange; default: return Colors.red; }
  }

  IconData _getMarkerIcon(String type) {
    switch (type.toLowerCase()) { case 'income': return Icons.add_circle; case 'expense': return Icons.remove_circle; case 'transfer': return Icons.swap_horiz; default: return Icons.location_on; }
  }

  void _addTransactionMarker(LatLng position, String description, String type, double amount, String date) {
    final color = _getMarkerColor(type);
    final icon = _getMarkerIcon(type);
    setState(() { _markers.add(Marker(point: position, width: 45, height: 45, child: GestureDetector(onTap: () => _showTransactionMarkerInfo(description, type, amount, date), child: Stack(alignment: Alignment.center, children: [Icon(Icons.location_on, color: color, size: 45), Positioned(top: 8, child: Icon(icon, color: Colors.white, size: 16))])))); });
  }

  void _showMarkerInfo(String title, String subtitle) {
    showDialog(context: context, builder: (c) => AlertDialog(backgroundColor: DesignTokens.surfaceDark, title: Text(title, style: GoogleFonts.poppins(color: Colors.white)), content: Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey[400])), actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text('Tutup', style: GoogleFonts.poppins(color: DesignTokens.primaryColor)))]));
  }

  void _showTransactionMarkerInfo(String description, String type, double amount, String date) {
    final typeLabel = type == 'income' ? 'Pemasukan' : type == 'expense' ? 'Pengeluaran' : 'Transfer';
    final color = _getMarkerColor(type);
    showDialog(context: context, builder: (c) => AlertDialog(
      backgroundColor: DesignTokens.surfaceDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [Icon(_getMarkerIcon(type), color: color, size: 24), const SizedBox(width: 12), Expanded(child: Text(description, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)))]),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildInfoRow('Tipe', typeLabel, color), const SizedBox(height: 12),
        _buildInfoRow('Jumlah', 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}', color),
        if (date.isNotEmpty) ...[const SizedBox(height: 12), _buildInfoRow('Tanggal', date.split('T')[0], Colors.grey)],
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text('Tutup', style: GoogleFonts.poppins(color: DesignTokens.primaryColor)))],
    ));
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14)), Text(value, style: GoogleFonts.poppins(color: color, fontSize: 14, fontWeight: FontWeight.w600))]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: DesignTokens.backgroundDark, title: Text('Peta Transaksi', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)), leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
        actions: [IconButton(icon: const Icon(Iconsax.refresh, color: Colors.white), onPressed: () { setState(() => _markers.clear()); _initializeLocation(); _loadTransactionMarkers(); }, tooltip: 'Muat ulang')]),
      body: Column(children: [
        const OfflineIndicator(),
        Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator()) : _errorMessage != null ? _buildErrorState() : FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: _currentPosition ?? const LatLng(-5.1477, 119.4327), initialZoom: 15.0, minZoom: 5.0, maxZoom: 18.0),
          children: [TileLayer(urlTemplate: MapProviderService.getTileUrlTemplate(), userAgentPackageName: 'com.example.financial_app'), MarkerLayer(markers: _markers)],
        )),
      ]),
      floatingActionButton: FloatingActionButton(heroTag: 'map_fab', onPressed: () async { final pos = await LocationService.getCurrentLatLng(); if (pos != null) _mapController.move(LatLng(pos.latitude, pos.longitude), 18.0); }, backgroundColor: DesignTokens.primaryColor, child: const Icon(Iconsax.gps, color: Colors.white)),
    );
  }
}
