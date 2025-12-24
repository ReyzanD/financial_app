import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/obligation_service.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Widget untuk menampilkan analytics dan trends untuk obligations
class BillAnalyticsView extends StatefulWidget {
  const BillAnalyticsView({super.key});

  @override
  State<BillAnalyticsView> createState() => _BillAnalyticsViewState();
}

class _BillAnalyticsViewState extends State<BillAnalyticsView> {
  final ObligationService _obligationService = ObligationService();
  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final obligations = await _obligationService.getObligations();
      final summary = await _obligationService.getObligationsSummary();

      // Calculate category breakdown
      final categoryBreakdown = <String, double>{};
      for (var obligation in obligations) {
        final category = obligation.category ?? 'other';
        categoryBreakdown[category] =
            (categoryBreakdown[category] ?? 0.0) + obligation.monthlyAmount;
      }

      // Calculate monthly trends (last 6 months)
      final monthlyTrends = await _calculateMonthlyTrends();

      setState(() {
        _analytics = {
          'totalObligations': obligations.length,
          'monthlyTotal': summary['monthlyTotal'] ?? 0.0,
          'totalDebt': summary['totalDebt'] ?? 0.0,
          'categoryBreakdown': categoryBreakdown,
          'monthlyTrends': monthlyTrends,
          'obligations': obligations,
        };
        _isLoading = false;
      });
    } catch (e) {
      LoggerService.error('Error loading analytics', error: e);
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _calculateMonthlyTrends() async {
    // Simplified - would need actual payment history data
    final trends = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      trends.add({
        'month': DateFormat('MMM yyyy', 'id_ID').format(month),
        'amount': 0.0, // Would calculate from payment history
      });
    }

    return trends;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          _buildSummaryCards(),
          const SizedBox(height: 24),

          // Category Breakdown
          _buildCategoryBreakdown(),
          const SizedBox(height: 24),

          // Monthly Trends
          _buildMonthlyTrends(),
          const SizedBox(height: 24),

          // Spending Forecast
          _buildSpendingForecast(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            AppLocalizations.of(context)!.monthly_total_label,
            CurrencyFormatter.formatRupiah(
              (_analytics['monthlyTotal'] as num?)?.toDouble() ?? 0.0,
            ),
            Iconsax.wallet_3,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            AppLocalizations.of(context)!.total_debt,
            CurrencyFormatter.formatRupiah(
              (_analytics['totalDebt'] as num?)?.toDouble() ?? 0.0,
            ),
            Iconsax.card,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final breakdown =
        _analytics['categoryBreakdown'] as Map<String, double>? ?? {};

    if (breakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = breakdown.values.fold(0.0, (sum, amount) => sum + amount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.category_breakdown,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...breakdown.entries.map((entry) {
            final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getCategoryName(entry.key),
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey[800],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getCategoryColor(entry.key),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        CurrencyFormatter.formatRupiah(entry.value.toInt()),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrends() {
    final trends =
        _analytics['monthlyTrends'] as List<Map<String, dynamic>>? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.monthly_trends,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (trends.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  AppLocalizations.of(context)!.no_trend_data,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...trends.map((trend) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      trend['month']?.toString() ?? '',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatRupiah(
                        ((trend['amount'] as num?)?.toDouble() ?? 0.0).toInt(),
                      ),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildSpendingForecast() {
    final monthlyTotal =
        (_analytics['monthlyTotal'] as num?)?.toDouble() ?? 0.0;
    final obligations = _analytics['obligations'] as List? ?? [];

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = daysInMonth - now.day;

    final upcomingObligations =
        obligations.where((o) {
          final obligation = o as dynamic;
          return obligation.daysUntilDue >= 0 &&
              obligation.daysUntilDue <= daysRemaining;
        }).toList();

    double upcomingTotal = 0.0;
    for (var obligation in upcomingObligations) {
      final o = obligation as dynamic;
      upcomingTotal += o.monthlyAmount;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.chart_2, color: const Color(0xFF8B5FBF), size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.spending_forecast,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildForecastItem(
            AppLocalizations.of(context)!.remaining_this_month,
            CurrencyFormatter.formatRupiah(upcomingTotal.toInt()),
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildForecastItem(
            AppLocalizations.of(context)!.monthly_total_label,
            CurrencyFormatter.formatRupiah(monthlyTotal.toInt()),
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildForecastItem(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  String _getCategoryName(String category) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return category;

    switch (category) {
      case 'utility':
        return l10n.utilities;
      case 'housing':
        return l10n.housing;
      case 'transportation':
        return l10n.transportation;
      case 'entertainment':
        return l10n.entertainment;
      case 'internet':
        return l10n.internet;
      case 'phone':
        return l10n.phone;
      case 'insurance':
        return l10n.insurance;
      case 'subscription':
        return l10n.subscription;
      case 'credit_card':
        return l10n.credit_card;
      case 'mortgage':
        return l10n.mortgage;
      case 'other':
        return l10n.other;
      default:
        return category;
    }
  }

  Color _getCategoryColor(String category) {
    const colorMap = {
      'utility': Colors.blue,
      'housing': Colors.green,
      'transportation': Colors.orange,
      'entertainment': Colors.purple,
      'internet': Colors.cyan,
      'phone': Colors.teal,
      'insurance': Colors.indigo,
      'subscription': Colors.pink,
      'credit_card': Colors.red,
      'mortgage': Colors.brown,
      'other': Colors.grey,
    };
    return colorMap[category] ?? Colors.grey;
  }
}
