import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/widgets/analytics/analytics_header.dart';
import 'package:financial_app/widgets/analytics/period_selector.dart';
import 'package:financial_app/widgets/analytics/spending_chart.dart';
import 'package:financial_app/widgets/analytics/category_breakdown.dart';
import 'package:financial_app/widgets/analytics/monthly_comparison.dart';
import 'package:financial_app/widgets/analytics/spending_insights.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/features/analytics/presentation/controllers/analytics_controller.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<AnalyticsController>();
      final l10n = AppLocalizations.of(context);
      if (l10n != null) {
        ctrl.initializePeriod(l10n.this_week);
      }
      if (!ctrl.isLoading && ctrl.transactions.isEmpty) {
        ctrl.loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            const AnalyticsHeader(),
            const OfflineIndicator(),
            Consumer<AnalyticsController>(
              builder: (context, ctrl, _) => PeriodSelector(
                selectedPeriod: ctrl.selectedPeriod,
                onPeriodChanged: (period) => ctrl.setPeriod(period),
              ),
            ),
            Expanded(
              child: Consumer<AnalyticsController>(
                builder: (context, ctrl, _) {
                  if (ctrl.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: DesignTokens.primaryColor),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: ctrl.refresh,
                    color: DesignTokens.primaryColor,
                    child: _buildBody(context, ctrl),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AnalyticsController ctrl) {
    if (ctrl.errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: ResponsiveHelper.padding(context),
        children: [
          Container(
            padding: ResponsiveHelper.padding(context, multiplier: 1.5),
            decoration: BoxDecoration(
              color: DesignTokens.surfaceDark,
              borderRadius: BorderRadius.circular(ResponsiveHelper.borderRadius(context, 16)),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline, color: Colors.red[400], size: ResponsiveHelper.iconSize(context, 40)),
                SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
                Text(
                  AppLocalizations.of(context)?.failed_to_load_analytics ?? 'Gagal memuat data analitik',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[300],
                    fontSize: ResponsiveHelper.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
                Text(
                  ctrl.errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: ResponsiveHelper.fontSize(context, 12)),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final filtered = ctrl.transactions;

    if (filtered.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: ResponsiveHelper.padding(context),
        children: [
          Container(
            padding: ResponsiveHelper.padding(context, multiplier: 2.0),
            decoration: BoxDecoration(
              color: DesignTokens.surfaceDark,
              borderRadius: BorderRadius.circular(ResponsiveHelper.borderRadius(context, 16)),
              border: Border.all(color: DesignTokens.borderDark),
            ),
            child: Column(
              children: [
                Icon(Icons.insights, color: Colors.grey[600], size: ResponsiveHelper.iconSize(context, 48)),
                SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
                Text(
                  l10n.no_transactions_for_period,
                  style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: ResponsiveHelper.fontSize(context, 16), fontWeight: FontWeight.w600),
                ),
                SizedBox(height: ResponsiveHelper.verticalSpacing(context, 4)),
                Text(
                  l10n.no_transactions_subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: ResponsiveHelper.fontSize(context, 12)),
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
          SpendingInsights(transactions: filtered, summary: ctrl.summary),
        ],
      ),
    );
  }
}
