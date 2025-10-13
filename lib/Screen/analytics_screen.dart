import 'package:flutter/material.dart';
import '../widgets/analytics/analytics_header.dart';
import '../widgets/analytics/period_selector.dart';
import '../widgets/analytics/spending_chart.dart';
import '../widgets/analytics/category_breakdown.dart';
import '../widgets/analytics/monthly_comparison.dart';
import '../widgets/analytics/spending_insights.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'Minggu Ini';

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SpendingChart(),
                    const SizedBox(height: 16),
                    const CategoryBreakdown(),
                    const SizedBox(height: 16),
                    const MonthlyComparison(),
                    const SizedBox(height: 16),
                    const SpendingInsights(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
