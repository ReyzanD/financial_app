import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/widgets/transactions/transaction_helpers.dart';
import 'package:financial_app/widgets/transactions/alternative_recommendation_card.dart';
import 'package:financial_app/widgets/transactions/alternative_suggestion_card.dart';
import 'package:financial_app/widgets/transactions/alternatives_screen.dart';
import 'package:financial_app/widgets/transactions/location_insight_card.dart';
import 'package:financial_app/models/location_recommendation.dart';
import 'package:financial_app/models/alternative_suggestion.dart';
import 'package:financial_app/models/place_visit.dart';
import 'package:financial_app/models/transaction_model.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/data/place_visit_data_service.dart';
import 'package:financial_app/services/data/price_observation_data_service.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/services/alternative_recommendation_engine.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/location_intelligence_service.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:latlong2/latlong.dart';
import 'package:financial_app/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback? onDeleted;
  final VoidCallback? onUpdated;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    this.onDeleted,
    this.onUpdated,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  LatLng? _transactionLocation;
  List<LocationRecommendation>? _alternativeRecommendations;
  List<AlternativeSuggestion>? _engineSuggestions;
  bool _isLoadingRecommendations = false;
  bool _isLoadingEngine = false;
  AppLocalizations? _l10n;
  final AlternativeRecommendationEngine _engine =
      getIt<AlternativeRecommendationEngine>();
  final PlaceVisitDataService _placeVisitDataService =
      getIt<PlaceVisitDataService>();
  final PriceObservationDataService _priceObservationDataService =
      getIt<PriceObservationDataService>();
  bool _isPriceTagged = false;
  bool _isTaggingPrice = false;

  @override
  void initState() {
    super.initState();
    _loadLocationData();
    _loadAlternativeRecommendations();
    _loadEngineSuggestions();
  }

  Future<void> _loadLocationData() async {
    if (_decodedLocationData != null &&
        _decodedLocationData!['latitude'] != null &&
        _decodedLocationData!['longitude'] != null) {
      setState(() {
        _transactionLocation = LatLng(
          _decodedLocationData!['latitude'] as double,
          _decodedLocationData!['longitude'] as double,
        );
      });
    }
  }

  Future<void> _loadAlternativeRecommendations() async {
    final category = widget.transaction['category'] ?? 'Uncategorized';

    setState(() => _isLoadingRecommendations = true);

    try {
      final recommendations = await getIt<LocationIntelligenceService>()
          .getCategoryLocationAdvice(category);

      if (mounted)
        setState(() => _alternativeRecommendations = recommendations);
    } catch (e) {
      LoggerService.error(
        'Error loading alternative recommendations',
        error: e,
      );
    } finally {
      if (mounted) setState(() => _isLoadingRecommendations = false);
    }
  }

  Future<void> _loadEngineSuggestions() async {
    try {
      final lat = widget.transaction['latitude'] as double?;
      final lng = widget.transaction['longitude'] as double?;
      final category = widget.transaction['category'] ?? 'Uncategorized';

      if (lat == null || lng == null) return;

      setState(() => _isLoadingEngine = true);

      // Build TransactionModel from the raw map
      final txModel = TransactionModel.fromJson(widget.transaction);

      // Upsert PlaceVisit — creates or updates from this transaction
      PlaceVisit placeVisit;
      if (txModel.locationData != null) {
        placeVisit = await _placeVisitDataService.upsertFromTransaction(
          txModel,
        );

        // Auto-create a PriceObservation from this transaction's amount
        try {
          await _priceObservationDataService.createFromTransaction(
            placeVisitId: placeVisit.id,
            transaction: txModel,
          );
          _isPriceTagged = true;
          LoggerService.info(
            '✅ PriceObservation auto-created for ${placeVisit.placeName}',
          );
        } catch (e) {
          LoggerService.error('Error auto-creating PriceObservation', error: e);
        }
      } else {
        // No structured location data — use a synthetic PlaceVisit
        placeVisit = PlaceVisit(
          id: widget.transaction['id']?.toString() ?? '',
          placeName: widget.transaction['location']?.toString() ?? category,
          latitude: lat,
          longitude: lng,
          category: category,
          firstVisit: DateTime.now(),
          lastVisit: DateTime.now(),
        );
      }

      // Get alternative suggestions from the engine
      final results = await _engine.getAlternativesForPlace(placeVisit);

      if (mounted) {
        setState(() => _engineSuggestions = results);
      }
    } catch (e) {
      LoggerService.error('Error loading engine suggestions', error: e);
    } finally {
      if (mounted) setState(() => _isLoadingEngine = false);
    }
  }

  /// Manually tag the current transaction's price as a PriceObservation.
  Future<void> _tagCurrentPrice() async {
    try {
      setState(() => _isTaggingPrice = true);

      final lat = widget.transaction['latitude'] as double?;
      final lng = widget.transaction['longitude'] as double?;
      if (lat == null || lng == null) {
        ErrorHandlerService.showWarningSnackbar(
          context,
          'Transaksi ini tidak memiliki data lokasi',
        );
        return;
      }

      final txModel = TransactionModel.fromJson(widget.transaction);
      PlaceVisit pv;
      try {
        pv = await _placeVisitDataService.upsertFromTransaction(txModel);
      } catch (_) {
        // If upsert fails (e.g. no location_data), find or create a basic one
        final existing = await _placeVisitDataService.findByApproximateLocation(
          lat,
          lng,
        );
        if (existing != null) {
          pv = existing;
        } else {
          final fallbackId =
              'pv_${lat}_${lng}_${DateTime.now().millisecondsSinceEpoch}';
          pv = PlaceVisit(
            id: fallbackId,
            placeName: widget.transaction['location']?.toString() ?? 'Unknown',
            latitude: lat,
            longitude: lng,
            category: widget.transaction['category'] ?? 'Uncategorized',
            firstVisit: DateTime.now(),
            lastVisit: DateTime.now(),
          );
        }
      }

      await _priceObservationDataService.createFromTransaction(
        placeVisitId: pv.id,
        transaction: txModel,
        source: 'self_reported',
      );

      if (mounted) {
        setState(() => _isPriceTagged = true);
        ErrorHandlerService.showSuccessSnackbar(
          context,
          'Harga tercatat: ${CurrencyFormatter.formatRupiah(txModel.amount)}',
        );
      }
    } catch (e) {
      LoggerService.error('Error tagging price', error: e);
      ErrorHandlerService.showErrorSnackbar(context, 'Gagal mencatat harga');
    } finally {
      if (mounted) setState(() => _isTaggingPrice = false);
    }
  }

  Map<String, dynamic>? _decodedLocationData;

  @override
  Widget build(BuildContext context) {
    _l10n = AppLocalizations.of(context);
    // Debug: Log the entire transaction data
    LoggerService.debug(
      'TransactionDetailScreen Data: ${json.encode(widget.transaction)}',
    );

    final isIncome = widget.transaction['type'] == 'income';
    final amount =
        double.tryParse(widget.transaction['amount']?.toString() ?? '0') ?? 0.0;
    final category = widget.transaction['category'] ?? 'Uncategorized';
    final date = widget.transaction['date'] as String? ?? '';
    final location = widget.transaction['location'] as String? ?? '';
    final notes = widget.transaction['description'] as String?;

    return Scaffold(
      backgroundColor: DesignTokens.surfaceModalAlt,
      appBar: AppBar(
        title: Text(
          'Detail Transaksi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: DesignTokens.surfaceModalAlt,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          tooltip: 'Kembali',
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.edit_2, color: Colors.white),
            tooltip: 'Edit',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => AddTransactionScreen(
                        transaction: widget.transaction,
                        onUpdated: () {
                          // Refresh parent screen via onUpdated
                          widget.onUpdated?.call();
                          // Close detail screen
                          Navigator.pop(context);
                        },
                      ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spacing4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction Basic Info
                  _buildTransactionCard(
                    isIncome,
                    amount,
                    category,
                    date,
                    location,
                    notes,
                  ),
                  const SizedBox(height: 20),

                  // Location Insight Section
                  if (widget.transaction['location'] != '') ...[
                    _buildLocationInsightSection(),
                    const SizedBox(height: 12),
                    // Price tagging button
                    _buildPriceTagButton(),
                    const SizedBox(height: 20),
                  ],

                  // Alternative Recommendations Section
                  _buildAlternativeRecommendationsSection(),
                  const SizedBox(height: 20),

                  // Transaction Notes & Details
                  _buildTransactionDetails(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    bool isIncome,
    double amount,
    String category,
    String date,
    String location,
    String? notes,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(color: DesignTokens.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: getCategoryColor(category).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  getCategoryIcon(category),
                  color: getCategoryColor(category),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.transaction['description'] as String? ?? 'No name',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$category • $location',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatRupiah(amount.abs()),
                    style: GoogleFonts.poppins(
                      color: isIncome ? Colors.green : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isIncome
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMedium,
                      ),
                    ),
                    child: Text(
                      isIncome ? 'PEMASUKAN' : 'PENGELUARAN',
                      style: GoogleFonts.poppins(
                        color: isIncome ? Colors.green : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes, color: Colors.grey[500], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notes,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationInsightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location Insight',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        LocationInsightCard(
          transactionId: widget.transaction['id']?.toString() ?? 'unknown',
          transactionLocation: _transactionLocation,
        ),
      ],
    );
  }

  Widget _buildPriceTagButton() {
    final amount =
        double.tryParse(widget.transaction['amount']?.toString() ?? '0') ?? 0.0;
    final hasLocation = widget.transaction['latitude'] != null;

    if (_isPriceTagged) {
      return Container(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: DesignTokens.spacing4,
        ),
        decoration: BoxDecoration(
          color: DesignTokens.successColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(
            color: DesignTokens.successColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Iconsax.tick_circle,
              color: DesignTokens.successColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Harga tercatat: ${CurrencyFormatter.formatRupiah(amount)}',
              style: GoogleFonts.poppins(
                color: DesignTokens.successColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (!hasLocation) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isTaggingPrice ? null : _tagCurrentPrice,
        icon:
            _isTaggingPrice
                ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: DesignTokens.primaryColor,
                  ),
                )
                : Icon(Iconsax.dollar_square, size: 18),
        label: Text(
          _isTaggingPrice
              ? 'Menyimpan...'
              : 'Catat Harga (${CurrencyFormatter.formatRupiah(amount)})',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignTokens.primaryColor,
          side: BorderSide(
            color: DesignTokens.primaryColor.withValues(alpha: 0.5),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          ),
        ),
      ),
    );
  }

  // Removed unused methods _buildLoadingInsight and _buildNoInsightAvailable

  Widget _buildAlternativeRecommendationsSection() {
    final lat = widget.transaction['latitude'] as double?;
    final lng = widget.transaction['longitude'] as double?;
    final category = widget.transaction['category'] ?? 'Uncategorized';
    final locationName = widget.transaction['location']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rekomendasi Alternatif',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_engineSuggestions != null && _engineSuggestions!.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => AlternativesScreen(
                            transactionId:
                                widget.transaction['id']?.toString() ?? '',
                            category: category,
                            latitude: lat,
                            longitude: lng,
                            locationName: locationName,
                          ),
                    ),
                  );
                },
                child: Text(
                  'Lihat Semua (${_engineSuggestions!.length})',
                  style: GoogleFonts.poppins(
                    color: DesignTokens.primaryColor,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // New engine-based results (top 3)
        if (_isLoadingEngine)
          _buildLoadingEngine()
        else if (_engineSuggestions != null &&
            _engineSuggestions!.isNotEmpty) ...[
          ..._engineSuggestions!
              .take(3)
              .map(
                (s) =>
                    AlternativeSuggestionCard(suggestion: s, isCompact: true),
              ),
          const SizedBox(height: 8),
        ],

        // Fallback: old recommendation service
        if (_engineSuggestions == null || _engineSuggestions!.isEmpty) ...[
          if (_isLoadingRecommendations)
            _buildLoadingRecommendations()
          else if (_alternativeRecommendations != null &&
              _alternativeRecommendations!.isNotEmpty)
            ..._alternativeRecommendations!
                .take(2)
                .map(
                  (recommendation) => AlternativeRecommendationCard(
                    recommendation: recommendation,
                  ),
                )
          else
            _buildNoRecommendationsAvailable(),
        ],
      ],
    );
  }

  Widget _buildLoadingEngine() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: DesignTokens.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mencari alternatif dari OpenStreetMap...',
              style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingRecommendations() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
      ),
      child: Row(
        children: [
          CircularProgressIndicator(color: DesignTokens.primaryColor),
          const SizedBox(width: 12),
          Text(
            'Mencari rekomendasi alternatif...',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRecommendationsAvailable() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
      ),
      child: Row(
        children: [
          Icon(Iconsax.info_circle, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text(
            _l10n?.no_alternative_recommendations ??
                'Tidak ada rekomendasi alternatif untuk kategori ini',
            style: GoogleFonts.poppins(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detail Transaksi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacing4),
          decoration: BoxDecoration(
            color: DesignTokens.surfaceDark,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          ),
          child: Column(
            children: [
              _buildDetailRow(
                _l10n?.date ?? 'Tanggal',
                formatDate(widget.transaction['date'] as String? ?? ''),
              ),
              _buildDetailRow(
                _l10n?.category ?? 'Kategori',
                widget.transaction['category'] ?? 'Uncategorized',
              ),
              _buildDetailRow(
                _l10n?.location ?? 'Lokasi',
                widget.transaction['location'] ?? '',
              ),
              _buildDetailRow(
                _l10n?.transaction_type ?? 'Tipe',
                widget.transaction['type'] == 'income'
                    ? (_l10n?.income ?? 'Pemasukan')
                    : (_l10n?.expense ?? 'Pengeluaran'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 14),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
