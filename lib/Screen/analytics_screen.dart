import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/analytics/analytics_header.dart';
import '../widgets/analytics/period_selector.dart';
import '../widgets/analytics/spending_chart.dart';
import '../widgets/analytics/category_breakdown.dart';
import '../widgets/analytics/monthly_comparison.dart';
import '../widgets/analytics/spending_insights.dart';
import '../services/api_service.dart';
import '../services/error_handler_service.dart';
import '../services/logger_service.dart';
import '../utils/responsive_helper.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'Minggu Ini';
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _transactions = [];
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      LoggerService.debug('Loading analytics data...');

      final now = DateTime.now();
      DateTime? startDate;
      DateTime? endDate = now;

      if (_selectedPeriod == 'Minggu Ini') {
        final today = DateTime(now.year, now.month, now.day);
        startDate = today.subtract(Duration(days: today.weekday - 1));
      } else if (_selectedPeriod == 'Bulan Ini') {
        startDate = DateTime(now.year, now.month, 1);
      } else if (_selectedPeriod == '3 Bulan') {
        startDate = DateTime(now.year, now.month - 2, 1);
      } else if (_selectedPeriod == 'Tahun Ini') {
        startDate = DateTime(now.year, 1, 1);
      }

      final transactionsData = await _apiService.getTransactions(
        limit: 100,
        startDate: startDate,
        endDate: endDate,
      );
      final summary = await _apiService.getFinancialSummary(
        year: now.year,
        month: now.month,
      );

      final transactions = List<dynamic>.from(
        transactionsData['transactions'] ?? [],
      );

      LoggerService.success('Loaded ${transactions.length} transactions');
      LoggerService.debug('Summary loaded', error: summary);

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      LoggerService.error('Error loading analytics', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = ErrorHandlerService.getUserFriendlyMessage(e);
        });
        if (context.mounted) {
          ErrorHandlerService.showErrorSnackbar(
            context,
            _errorMessage!,
            onRetry: _loadData,
          );
        }
      }
    }
  }

  List<dynamic> _getFilteredTransactions() {
    return _transactions;
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: ResponsiveHelper.padding(context),
        children: [
          Container(
            padding: ResponsiveHelper.padding(context, multiplier: 1.5),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.borderRadius(context, 16),
              ),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red[400],
                  size: ResponsiveHelper.iconSize(context, 40),
                ),
                SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
                Text(
                  'Gagal memuat analitik',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[300],
                    fontSize: ResponsiveHelper.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: ResponsiveHelper.fontSize(context, 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final filtered = _getFilteredTransactions();

    if (filtered.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: ResponsiveHelper.padding(context),
        children: [
          Container(
            padding: ResponsiveHelper.padding(context, multiplier: 2.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.borderRadius(context, 16),
              ),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.insights,
                  color: Colors.grey[600],
                  size: ResponsiveHelper.iconSize(context, 48),
                ),
                SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
                Text(
                  'Belum ada data untuk periode ini',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: ResponsiveHelper.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.verticalSpacing(context, 4)),
                Text(
                  'Tambahkan transaksi untuk melihat analitik keuangan Anda.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: ResponsiveHelper.fontSize(context, 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: ResponsiveHelper.padding(context),
      child: Column(
        children: [
          SpendingChart(transactions: filtered),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 16)),
          CategoryBreakdown(transactions: filtered),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 16)),
          MonthlyComparison(transactions: filtered),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 16)),
          SpendingInsights(transactions: filtered, summary: _summary),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            const AnalyticsHeader(),
            PeriodSelector(
              selectedPeriod: _selectedPeriod,
              onPeriodChanged: (period) {
                setState(() {
                  _selectedPeriod = period;
                });
                _loadData();
              },
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF8B5FBF),
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: _loadData,
                        color: const Color(0xFF8B5FBF),
                        child: _buildBody(),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
