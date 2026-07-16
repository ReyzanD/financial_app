import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/models/alternative_suggestion.dart';
import 'package:financial_app/models/place_visit.dart';
import 'package:financial_app/widgets/transactions/alternative_suggestion_card.dart';
import 'package:financial_app/services/data/place_visit_data_service.dart';
import 'package:financial_app/services/data/price_observation_data_service.dart';
import 'package:financial_app/services/alternative_recommendation_engine.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/utils/formatters.dart';

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
  final PriceObservationDataService _priceObservationDataService =
      getIt<PriceObservationDataService>();

  List<AlternativeSuggestion> _suggestions = [];
  bool _isLoading = true;
  String? _error;
  PlaceVisit? _originPlaceVisit;

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
      List<AlternativeSuggestion> results = [];
      if (widget.latitude != null && widget.longitude != null) {
        // Persist (or reuse) the origin PlaceVisit so price observations can
        // link to a real DB row — required by the FK constraint.
        final pv = await _placeVisitDataService.findOrCreateByLocation(
          latitude: widget.latitude!,
          longitude: widget.longitude!,
          category: widget.category,
          placeName: widget.locationName ?? widget.category,
        );
        _originPlaceVisit = pv;
        results = await _engine.getAlternativesForPlace(
          pv,
          forceRefresh: forceRefresh,
        );
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

  /// Open a bottom sheet letting the user record "I paid X here" for the
  /// origin place. Persisted as a self_reported price observation, then the
  /// engine is re-run so distance-only suggestions can become price-aware.
  Future<void> _tagMyPrice() async {
    if (_originPlaceVisit == null) return;

    final controller = TextEditingController();
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusLarge),
        ),
      ),
      builder:
          (sheetContext) => Padding(
            padding: EdgeInsets.only(
              left: DesignTokens.spacing4,
              right: DesignTokens.spacing4,
              top: DesignTokens.spacing4,
              bottom:
                  MediaQuery.of(sheetContext).viewInsets.bottom +
                  DesignTokens.spacing4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tag harga di ${_originPlaceVisit!.placeName}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: DesignTokens.spacing2),
                Text(
                  'Masukkan harga yang Anda bayar agar rekomendasi bisa membandingkan harga, bukan hanya jarak.',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: DesignTokens.spacing4),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Harga (IDR)',
                    labelStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                    prefixText: 'Rp ',
                    filled: true,
                    fillColor: DesignTokens.backgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMedium,
                      ),
                      borderSide: BorderSide(color: DesignTokens.borderDark),
                    ),
                  ),
                ),
                SizedBox(height: DesignTokens.spacing4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final parsed = double.tryParse(
                        controller.text.replaceAll(RegExp(r'[^0-9.]'), ''),
                      );
                      if (parsed == null || parsed <= 0) {
                        ErrorHandlerService.showWarningSnackbar(
                          sheetContext,
                          'Masukkan harga yang valid',
                        );
                        return;
                      }
                      Navigator.pop(sheetContext, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Simpan',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );

    if (submitted != true) return;

    final price = double.tryParse(
      controller.text.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    if (price == null || price <= 0) return;

    try {
      await _priceObservationDataService.createSelfReported(
        placeVisitId: _originPlaceVisit!.id,
        category: widget.category,
        price: price,
      );
      if (mounted) {
        ErrorHandlerService.showSuccessSnackbar(
          context,
          'Harga tercatat: ${CurrencyFormatter.formatRupiah(price)}',
        );
        await _loadSuggestions(forceRefresh: true);
      }
    } catch (e) {
      LoggerService.error('Error tagging self-reported price', error: e);
      if (mounted)
        ErrorHandlerService.showErrorSnackbar(context, 'Gagal mencatat harga');
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
          tooltip: 'Kembali',
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.tag, color: Colors.white),
            onPressed: _tagMyPrice,
            tooltip: 'Tag harga di sini',
          ),
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
        border: Border(bottom: BorderSide(color: DesignTokens.borderDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.location,
                color: DesignTokens.primaryColor,
                size: 20,
              ),
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
          const SizedBox(height: DesignTokens.spacing2),
          Text(
            'Kategori: ${widget.category}',
            style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
          ),
          if (widget.latitude != null && widget.longitude != null) ...[
            const SizedBox(height: DesignTokens.spacing1),
            Text(
              '${widget.latitude!.toStringAsFixed(4)}, ${widget.longitude!.toStringAsFixed(4)}',
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 10),
            ),
          ],
          const SizedBox(height: DesignTokens.spacing3),
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
        itemBuilder:
            (context, index) =>
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
          const SizedBox(height: DesignTokens.spacing4),
          Text(
            'Mencari alternatif dari OpenStreetMap...',
            style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: DesignTokens.spacing2),
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
            const SizedBox(height: DesignTokens.spacing4),
            Text(
              _error!,
              style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacing5),
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
            const SizedBox(height: DesignTokens.spacing4),
            Text(
              'Belum ada alternatif ditemukan',
              style: GoogleFonts.poppins(
                color: Colors.grey[500],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: DesignTokens.spacing2),
            Text(
              'Coba refresh atau perluas area pencarian.\n'
              'Data berasal dari OpenStreetMap.',
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacing5),
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
