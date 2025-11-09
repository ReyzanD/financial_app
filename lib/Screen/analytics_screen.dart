import 'package:flutter/material.dart';
import '../widgets/analytics/analytics_header.dart';
import '../widgets/analytics/period_selector.dart';
import '../widgets/analytics/spending_chart.dart';
import '../widgets/analytics/category_breakdown.dart';
import '../widgets/analytics/monthly_comparison.dart';
import '../widgets/analytics/spending_insights.dart';
import '../services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'Minggu Ini';
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _transactions = [];
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      print('📊 Loading analytics data...');
      final transactions = await _apiService.getTransactions(limit: 100);
      final summary = await _apiService.getFinancialSummary();

      print('✅ Loaded ${transactions.length} transactions');
      print('✅ Summary: $summary');
      if (transactions.isNotEmpty) {
        print('📝 Sample transaction: ${transactions.first}');
      }

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading analytics: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              SpendingChart(transactions: _transactions),
                              const SizedBox(height: 16),
                              CategoryBreakdown(transactions: _transactions),
                              const SizedBox(height: 16),
                              MonthlyComparison(transactions: _transactions),
                              const SizedBox(height: 16),
                              SpendingInsights(
                                transactions: _transactions,
                                summary: _summary,
                              ),
                            ],
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
