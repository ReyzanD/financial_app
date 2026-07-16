import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/features/forecast/presentation/controllers/forecast_controller.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ForecastController>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            l10n?.forecast_and_prediction ??
                                'Forecast & Prediksi',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Tooltip(
                              message:
                                  'Tip: Forecast dapat diakses dari More > Forecast',
                              decoration: BoxDecoration(
                                color: DesignTokens.surfaceDark,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Iconsax.info_circle,
                                color: Colors.grey[500],
                                size: 20,
                              ),
                            ),
                            Consumer<ForecastController>(
                              builder:
                                  (_, ctrl, __) => IconButton(
                                    icon: const Icon(
                                      Iconsax.refresh,
                                      color: Colors.white,
                                    ),
                                    tooltip: 'Segarkan',
                                    onPressed: ctrl.refresh,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Consumer<ForecastController>(
                      builder: (context, ctrl, _) {
                        if (ctrl.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: DesignTokens.primaryColor,
                            ),
                          );
                        }
                        if (ctrl.error != null) return _buildErrorState(ctrl);
                        return RefreshIndicator(
                          onRefresh: ctrl.refresh,
                          color: DesignTokens.primaryColor,
                          child: ListView(
                            padding: const EdgeInsets.all(DesignTokens.spacing4),
                            children: [
                              _buildForecastSummary(ctrl),
                              const SizedBox(height: 20),
                              _buildSpendingTrendChart(ctrl),
                              const SizedBox(height: 20),
                              if (ctrl.budgetRisks.isNotEmpty) ...[
                                _buildBudgetRisks(ctrl),
                                const SizedBox(height: 20),
                              ],
                              if (ctrl.categoryForecasts.isNotEmpty) ...[
                                _buildCategoryForecast(ctrl),
                                const SizedBox(height: 20),
                              ],
                              if (ctrl.suggestedBudgets.isNotEmpty) ...[
                                _buildSuggestedBudgets(ctrl),
                                const SizedBox(height: 20),
                              ],
                              if (ctrl.patternAnalysis['trends'] != null)
                                _buildSpendingInsights(ctrl),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ForecastController ctrl) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.warning_2, size: 64, color: DesignTokens.errorColor),
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                l10n?.failed_to_load_forecast ?? 'Gagal Memuat Forecast',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                'Butuh data transaksi untuk membuat prediksi',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: ctrl.refresh,
              icon: const Icon(Iconsax.refresh),
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

  // ---- Build sections ----

  Widget _buildForecastSummary(ForecastController ctrl) {
    final l10n = AppLocalizations.of(context);
    final ef = ctrl.expenseForecast;
    final forecastAmount = ef['forecastAmount'] as double? ?? 0.0;
    final confidence = ef['confidence'] as double? ?? 0.0;
    final trend = ef['trend'] as String? ?? 'unknown';
    final ci = ef['confidence_interval'] as Map? ?? {};
    final lower = ci['lower'] as double? ?? 0.0;
    final upper = ci['upper'] as double? ?? 0.0;

    final trendIcon = switch (trend) {
      'increasing' => Icons.trending_up,
      'decreasing' => Icons.trending_down,
      _ => Icons.trending_flat,
    };
    final trendColor = switch (trend) {
      'increasing' => Colors.red[400],
      'decreasing' => Colors.green[400],
      _ => Colors.grey[400],
    };

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
              Icon(Iconsax.lamp, color: DesignTokens.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Prediksi 30 Hari Kedepan',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Rp ${_formatNumber(forecastAmount)}',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: DesignTokens.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(trendIcon, size: 20, color: trendColor),
              const SizedBox(width: 4),
              Text(
                trend == 'increasing'
                    ? (l10n?.spending_increased ?? 'Pengeluaran meningkat')
                    : trend == 'decreasing'
                    ? (l10n?.spending_decreased ?? 'Pengeluaran menurun')
                    : (l10n?.spending_stable ?? 'Pengeluaran stabil'),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: trendColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildConfidenceBar(confidence),
          const SizedBox(height: 8),
          Text(
            'Akurasi: ${(confidence * 100).toInt()}%',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: DesignTokens.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      'Minimum',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: DesignTokens.textSecondaryDark,
                      ),
                    ),
                    Text(
                      'Rp ${_formatNumber(lower)}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  '95% Confidence',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: DesignTokens.textTertiaryDark,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      'Maksimum',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: DesignTokens.textSecondaryDark,
                      ),
                    ),
                    Text(
                      'Rp ${_formatNumber(upper)}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBar(double confidence) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: confidence,
        minHeight: 8,
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        valueColor: AlwaysStoppedAnimation<Color>(
          confidence > 0.7
              ? DesignTokens.successColor
              : confidence > 0.5
              ? Colors.orange
              : Colors.red,
        ),
      ),
    );
  }

  Widget _buildSpendingTrendChart(ForecastController ctrl) {
    final l10n = AppLocalizations.of(context);
    final periodData = ctrl.patternAnalysis['period_data'] as Map? ?? {};
    if (periodData.isEmpty) return const SizedBox.shrink();

    final sortedMonths = periodData.keys.toList()..sort();
    final expenses =
        sortedMonths
            .map((m) => (periodData[m]['expense'] as num?)?.toDouble() ?? 0.0)
            .toList();
    final incomes =
        sortedMonths
            .map((m) => (periodData[m]['income'] as num?)?.toDouble() ?? 0.0)
            .toList();
    if (expenses.length < 2) return const SizedBox.shrink();

    final maxVal = [...expenses, ...incomes].reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return const SizedBox.shrink();

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
          Text(
            'Tren Pengeluaran 3 Bulan',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget:
                          (value, meta) => Text(
                            'Rp${(value / 1000000).toStringAsFixed(0)}jt',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: DesignTokens.textSecondaryDark,
                            ),
                          ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= sortedMonths.length)
                          return const SizedBox.shrink();
                        final parts = sortedMonths[value.toInt()].split('-');
                        return Text(
                          _monthName(int.tryParse(parts[1]) ?? 1),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: DesignTokens.textSecondaryDark,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  sortedMonths.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: expenses[i],
                        color: DesignTokens.errorColor,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: incomes[i],
                        color: DesignTokens.successColor,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(
                l10n?.expense ?? 'Pengeluaran',
                DesignTokens.errorColor,
              ),
              const SizedBox(width: 20),
              _buildLegend(
                l10n?.income ?? 'Pemasukan',
                DesignTokens.successColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetRisks(ForecastController ctrl) {
    final l10n = AppLocalizations.of(context);
    final critical =
        ctrl.budgetRisks
            .where(
              (r) => r['risk_level'] == 'critical' || r['risk_level'] == 'high',
            )
            .toList();
    if (critical.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DesignTokens.surfaceDark,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          border: Border.all(color: DesignTokens.borderDark),
        ),
        child: Row(
          children: [
            Icon(
              Iconsax.tick_circle,
              color: DesignTokens.successColor,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n?.all_budgets_safe ?? 'Semua budget dalam kondisi aman',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: DesignTokens.successColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

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
              Icon(Iconsax.warning_2, color: DesignTokens.warningColor),
              const SizedBox(width: 8),
              Text(
                l10n?.budget_warning ?? 'Peringatan Budget',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...critical.map((risk) => _buildBudgetRiskItem(risk)),
        ],
      ),
    );
  }

  Widget _buildBudgetRiskItem(Map<String, dynamic> risk) {
    final category = risk['category_name'] as String? ?? 'Tidak Diketahui';
    final usagePercent = (risk['usage_percent'] as num?)?.toDouble() ?? 0.0;
    final riskLevel = risk['risk_level'] as String? ?? 'unknown';
    final remaining = (risk['remaining'] as num?)?.toDouble() ?? 0.0;
    final exhaustion = risk['exhaustion_prediction'] as Map? ?? {};
    final daysUntil = exhaustion['days_until_exhaustion'] as int?;

    final color = switch (riskLevel) {
      'critical' => DesignTokens.errorColor,
      'high' => DesignTokens.warningColor,
      'medium' => DesignTokens.warningColor,
      _ => DesignTokens.successColor,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  category,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                ),
                child: Text(
                  '${usagePercent.toInt()}%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: usagePercent / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            daysUntil != null
                ? 'Sisa Rp ${_formatNumber(remaining)} - Habis dalam $daysUntil hari'
                : 'Sisa Rp ${_formatNumber(remaining)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: DesignTokens.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryForecast(ForecastController ctrl) {
    final sorted =
        ctrl.categoryForecasts.entries.toList()
          ..sort((a, b) => b.value.amount.compareTo(a.value.amount));

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
              Icon(Iconsax.category, color: DesignTokens.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Prediksi per Kategori',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...sorted
              .take(8)
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: DesignTokens.primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        'Rp ${_formatNumber(entry.value.toDouble())}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildSuggestedBudgets(ForecastController ctrl) {
    final sorted =
        ctrl.suggestedBudgets.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

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
              Icon(Iconsax.lamp, color: DesignTokens.warningColor),
              const SizedBox(width: 8),
              Text(
                'Saran Budget Optimal',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Berdasarkan rata-rata pengeluaran + buffer 10%',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: DesignTokens.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 12),
          ...sorted.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.warningColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                      border: Border.all(
                        color: DesignTokens.warningColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Rp ${_formatNumber(entry.value.toDouble())}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.warningColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingInsights(ForecastController ctrl) {
    final l10n = AppLocalizations.of(context);
    final trends = ctrl.patternAnalysis['trends'] as Map? ?? {};
    final dayPatterns =
        ctrl.patternAnalysis['day_of_week_patterns'] as Map? ?? {};
    final merchants =
        (ctrl.patternAnalysis['frequent_merchants'] as List?) ?? [];

    final insights = <Widget>[];

    final expenseTrend = trends['expense_trend'] as String?;
    final expenseChange = trends['expense_change_percent'] as double? ?? 0.0;
    if (expenseTrend != null && expenseTrend != 'insufficient_data') {
      final icon =
          expenseTrend == 'increasing'
              ? Icons.trending_up
              : expenseTrend == 'decreasing'
              ? Icons.trending_down
              : Icons.trending_flat;
      final color =
          expenseTrend == 'increasing'
              ? DesignTokens.errorColor
              : expenseTrend == 'decreasing'
              ? DesignTokens.successColor
              : DesignTokens.textSecondaryDark;
      final text =
          expenseTrend == 'increasing'
              ? 'Pengeluaran meningkat ${expenseChange.abs().toStringAsFixed(1)}% dalam 3 bulan terakhir'
              : expenseTrend == 'decreasing'
              ? 'Pengeluaran menurun ${expenseChange.abs().toStringAsFixed(1)}% - bagus!'
              : 'Pengeluaran stabil dalam 3 bulan terakhir';
      insights.add(_buildInsightCard(icon, color, text));
    }

    final savingsTrend = trends['savings_rate_trend'] as String?;
    if (savingsTrend != null && savingsTrend != 'insufficient_data') {
      final icon =
          savingsTrend == 'improving'
              ? Icons.savings
              : savingsTrend == 'declining'
              ? Icons.warning
              : Icons.trending_flat;
      final color =
          savingsTrend == 'improving'
              ? DesignTokens.successColor
              : savingsTrend == 'declining'
              ? DesignTokens.warningColor
              : DesignTokens.textSecondaryDark;
      final text =
          savingsTrend == 'improving'
              ? 'Tingkat tabungan Anda membaik'
              : savingsTrend == 'declining'
              ? 'Tingkat tabungan menurun, perhatikan pengeluaran'
              : 'Tingkat tabungan stabil';
      insights.add(_buildInsightCard(icon, color, text));
    }

    final peakDay = dayPatterns['peak_day'] as String?;
    if (peakDay != null) {
      insights.add(
        _buildInsightCard(
          Iconsax.calendar,
          DesignTokens.infoColor,
          '${l10n?.highest_spending_day ?? 'Pengeluaran tertinggi pada hari'} $peakDay',
        ),
      );
    }

    final frequentMerchants =
        merchants.where((m) => (m['frequency'] as int? ?? 0) >= 3).toList();
    if (frequentMerchants.isNotEmpty) {
      final top = frequentMerchants.first;
      insights.add(
        _buildInsightCard(
          Iconsax.shop,
          DesignTokens.primaryColor,
          'Merchant paling sering: ${top['merchant']} (${top['frequency']}x)',
        ),
      );
    }

    if (insights.isEmpty) return const SizedBox.shrink();

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
              Icon(Iconsax.lamp_charge, color: DesignTokens.infoColor),
              const SizedBox(width: 8),
              Text(
                'Wawasan Pengeluaran',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...insights,
        ],
      ),
    );
  }

  Widget _buildInsightCard(IconData icon, Color color, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
        ),
      ],
    );
  }

  String _formatNumber(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  String _monthName(int month) {
    const names = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return names[month];
  }
}
