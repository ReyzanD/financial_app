import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/widgets/transactions/transaction_helpers.dart';
import 'package:financial_app/widgets/transactions/alternative_recommendation_card.dart';
import 'package:financial_app/widgets/transactions/location_insight_card.dart';
import 'package:financial_app/models/location_recommendation.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:financial_app/Screen/add_transaction_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback? onDeleted;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    this.onDeleted,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  LatLng? _transactionLocation;
  List<LocationRecommendation>? _alternativeRecommendations;
  bool _isLoadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    _loadLocationData();
    _loadAlternativeRecommendations();
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
      final recommendations = await LocationRecommendationService()
          .getCategoryBasedAlternatives(category, _decodedLocationData);

      setState(() => _alternativeRecommendations = recommendations);
    } catch (e) {
      LoggerService.error('Error loading alternative recommendations', error: e);
    } finally {
      setState(() => _isLoadingRecommendations = false);
    }
  }

  Map<String, dynamic>? _decodedLocationData;

  @override
  Widget build(BuildContext context) {
    // Debug: Log the entire transaction data
    LoggerService.debug('TransactionDetailScreen Data: ${json.encode(widget.transaction)}');

    final isIncome = widget.transaction['type'] == 'income';
    final amount =
        double.tryParse(widget.transaction['amount']?.toString() ?? '0') ?? 0.0;
    final category = widget.transaction['category'] ?? 'Uncategorized';
    final date = widget.transaction['date'] as String? ?? '';
    final location = widget.transaction['location'] as String? ?? '';
    final notes = widget.transaction['description'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(
          'Detail Transaksi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.edit_2, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => AddTransactionScreen(
                        transaction: widget.transaction,
                        onUpdated: () {
                          // Refresh parent screen
                          widget.onDeleted?.call();
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
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
                  color: getCategoryColor(category).withOpacity(0.2),
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
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
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

  // Removed unused methods _buildLoadingInsight and _buildNoInsightAvailable

  Widget _buildAlternativeRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rekomendasi Alternatif',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        if (_isLoadingRecommendations)
          _buildLoadingRecommendations()
        else if (_alternativeRecommendations != null &&
            _alternativeRecommendations!.isNotEmpty)
          ..._alternativeRecommendations!.map(
            (recommendation) =>
                AlternativeRecommendationCard(recommendation: recommendation),
          )
        else
          _buildNoRecommendationsAvailable(),
      ],
    );
  }

  Widget _buildLoadingRecommendations() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircularProgressIndicator(color: const Color(0xFF8B5FBF)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Iconsax.info_circle, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text(
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildDetailRow(
                'Tanggal',
                formatDate(widget.transaction['date'] as String? ?? ''),
              ),
              _buildDetailRow(
                'Kategori',
                widget.transaction['category'] ?? 'Uncategorized',
              ),
              _buildDetailRow('Lokasi', widget.transaction['location'] ?? ''),
              _buildDetailRow(
                'Tipe',
                widget.transaction['type'] == 'income'
                    ? 'Pemasukan'
                    : 'Pengeluaran',
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
