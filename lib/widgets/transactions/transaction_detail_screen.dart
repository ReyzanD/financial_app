import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/widgets/transactions/transaction_helpers.dart';
import 'package:financial_app/widgets/transactions/location_insight_card.dart';
import 'package:financial_app/widgets/transactions/alternative_recommendation_card.dart';
import 'package:financial_app/models/location_recommendation.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  LocationInsight? _locationInsight;
  bool _isLoadingInsight = false;
  List<LocationRecommendation>? _alternativeRecommendations;
  bool _isLoadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    _loadLocationInsight();
    _loadAlternativeRecommendations();
  }

  Future<void> _loadLocationInsight() async {
    if (widget.transaction['locationData'] == null) return;

    setState(() => _isLoadingInsight = true);

    try {
      // Simulate API call for location insight
      await Future.delayed(const Duration(seconds: 2));
      // For now, create a mock insight
      setState(
        () =>
            _locationInsight = LocationInsight(
              averagePrice: 85000,
              priceComparison: '15% lebih mahal dari rata-rata',
              recommendation:
                  'Coba cari tempat yang lebih hemat di sekitar area ini',
              savingsPotential: 12750,
            ),
      );
    } catch (e) {
      print('Error loading location insight: $e');
    } finally {
      setState(() => _isLoadingInsight = false);
    }
  }

  Future<void> _loadAlternativeRecommendations() async {
    final category = widget.transaction['category'] as String;
    final locationData =
        widget.transaction['locationData'] as Map<String, dynamic>?;

    setState(() => _isLoadingRecommendations = true);

    try {
      final recommendations = await LocationRecommendationService()
          .getCategoryBasedAlternatives(category, locationData);

      setState(() => _alternativeRecommendations = recommendations);
    } catch (e) {
      print('Error loading alternative recommendations: $e');
    } finally {
      setState(() => _isLoadingRecommendations = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.transaction['type'] == 'income';
    final amount = widget.transaction['amount'] as int;
    final category = widget.transaction['category'] as String;
    final date = widget.transaction['date'] as String;
    final location = widget.transaction['location'] as String;
    final notes = widget.transaction['notes'] as String?;

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
            if (widget.transaction['locationData'] != null) ...[
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
    int amount,
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
                      widget.transaction['name'] as String,
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
          'Analisis Lokasi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        if (_isLoadingInsight)
          _buildLoadingInsight()
        else if (_locationInsight != null)
          LocationInsightCard(insight: _locationInsight!)
        else
          _buildNoInsightAvailable(),
      ],
    );
  }

  Widget _buildLoadingInsight() {
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
            'Menganalisis harga lokasi...',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildNoInsightAvailable() {
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
            'Tidak ada data lokasi untuk analisis',
            style: GoogleFonts.poppins(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

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
                formatDate(widget.transaction['date'] as String),
              ),
              _buildDetailRow(
                'Kategori',
                widget.transaction['category'] as String,
              ),
              _buildDetailRow(
                'Lokasi',
                widget.transaction['location'] as String,
              ),
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
