import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/models/alternative_suggestion.dart';
import 'package:financial_app/models/place_visit.dart';
import 'package:financial_app/widgets/transactions/alternative_suggestion_card.dart';
import 'package:financial_app/services/data/place_visit_data_service.dart';
import 'package:financial_app/services/alternative_recommendation_engine.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/utils/design_tokens.dart';

/// Full-screen view of alternative place suggestions for a transaction.
class AlternativesScreen extends StatefulWidget {
  final String transactionId;
  final String category;
  final double? latitude;
  final double? longitude;
  final String? locationName;

  const AlternativesScreen({
    super.key,
    required this.transactionId,
    required this.category,
    this.latitude,
    this.longitude,
    this.locationName,
  });

  @override
  State<AlternativesScreen> createState() => _AlternativesScreenState();
}

class _AlternativesScreenState extends State<AlternativesScreen> {
  final AlternativeRecommendationEngine _engine =
      getIt<AlternativeRecommendationEngine>();
  final PlaceVisitDataService _placeVisitDataService =
      getIt<PlaceVisitDataService>();

  List<AlternativeSuggestion> _suggestions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Try to find or create a PlaceVisit for this transaction
      // First, check if we already have one by approximate location
      List<AlternativeSuggestion> results = [];
      if (widget.latitude != null && widget.longitude != null) {
        final existingPV = await _placeVisitDataService.findByApproximateLocation(
          widget.latitude!,
          widget.longitude!,
        );

        if (existingPV != null) {
          results = await _engine.getAlternativesForPlace(
            existingPV,
            forceRefresh: forceRefresh,
          );
        } else {
          // No PlaceVisit yet — create a synthetic one for this query
          final syntheticPV = PlaceVisit(
            id: widget.transactionId,
            placeName: widget.locationName ?? widget.category,
            latitude: widget.latitude ?? 0.0,
            longitude: widget.longitude ?? 0.0,
            category: widget.category,
            firstVisit: DateTime.now(),
            lastVisit: DateTime.now(),
          );
          results = await _engine.getAlternativesForPlace(
            syntheticPV,
            forceRefresh: forceRefresh,
          );
        }
      } else {
        _error = 'Transaksi ini tidak memiliki data lokasi';
      }

      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      LoggerService.error('Error loading alternatives', error: e);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: AppBar(
        title: Text(
          'Alternatif Hemat',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: DesignTokens.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh, color: Colors.white),
            onPressed: () => _loadSuggestions(forceRefresh: true),
            tooltip: 'Refresh dari OpenStreetMap',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary header
          _buildHeader(),
          // Content
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final count = _suggestions.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        border: Border(
          bottom: BorderSide(color: DesignTokens.borderDark),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.location, color: DesignTokens.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.locationName ?? 'Lokasi',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Kategori: ${widget.category}',
            style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
          ),
          if (widget.latitude != null && widget.longitude != null) ...[
            const SizedBox(height: 4),
            Text(
              '${widget.latitude!.toStringAsFixed(4)}, ${widget.longitude!.toStringAsFixed(4)}',
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 10),
            ),
          ],
          const SizedBox(height: 12),
          if (!_isLoading)
            Text(
              '$count ${count == 1 ? 'alternatif ditemukan' : 'alternatif ditemukan'}',
              style: GoogleFonts.poppins(
                color: count > 0 ? DesignTokens.successColor : Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError();
    if (_suggestions.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      onRefresh: () => _loadSuggestions(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(DesignTokens.spacing4),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) =>
            AlternativeSuggestionCard(suggestion: _suggestions[index]),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: DesignTokens.primaryColor),
          const SizedBox(height: 16),
          Text(
            'Mencari alternatif dari OpenStreetMap...',
            style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'Radius 1 km di sekitar lokasi',
            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.warning_2, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _loadSuggestions(forceRefresh: true),
              icon: const Icon(Iconsax.refresh, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.empty_wallet, color: Colors.grey[600], size: 48),
            const SizedBox(height: 16),
            Text(
              'Belum ada alternatif ditemukan',
              style: GoogleFonts.poppins(
                color: Colors.grey[500],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba refresh atau perluas area pencarian.\n'
              'Data berasal dari OpenStreetMap.',
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _loadSuggestions(forceRefresh: true),
              icon: const Icon(Iconsax.refresh, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
