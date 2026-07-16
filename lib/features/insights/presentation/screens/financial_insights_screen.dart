import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/goal_forecasting_service.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/widgets/common/empty_state.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/features/insights/presentation/controllers/insights_controller.dart';

class FinancialInsightsScreen extends StatefulWidget {
  /// When [embedded] is true (e.g. inside AnalyticsHubScreen),
  /// the own AppBar is suppressed and refresh is shown inline.
  final bool embedded;

  const FinancialInsightsScreen({super.key, this.embedded = false});

  @override
  State<FinancialInsightsScreen> createState() => _FinancialInsightsScreenState();
}

class _FinancialInsightsScreenState extends State<FinancialInsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsightsController>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: DesignTokens.surfaceDark,
      appBar:
          widget.embedded
              ? null
              : AppBar(
                title: Text(
                  'Wawasan Keuangan',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                backgroundColor: DesignTokens.surfaceDark,
                actions: [
                  Consumer<InsightsController>(
                    builder:
                        (_, ctrl, __) =>
                            IconButton(icon: const Icon(Iconsax.refresh, color: Colors.white), onPressed: ctrl.refresh),
                  ),
                ],
              ),
      body: Consumer<InsightsController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoading) {
            return const Center(child: CircularProgressIndicator(color: DesignTokens.primaryColor));
          }
          if (ctrl.errorMessage != null) {
            return _buildErrorState(ctrl, l10n);
          }
          return RefreshIndicator(
            onRefresh: ctrl.refresh,
            color: DesignTokens.primaryColor,
            child: ListView(
              padding: const EdgeInsets.all(DesignTokens.spacing4),
              children: [
                if (widget.embedded)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Iconsax.refresh, color: Colors.white70),
                      onPressed: ctrl.refresh,
                      tooltip: 'Refresh',
                    ),
                  ),
                const OfflineIndicator(),
                const SizedBox(height: DesignTokens.spacing4),
                _buildHealthScoreCard(ctrl),
                const SizedBox(height: DesignTokens.spacing4),
                _buildInsightsCard(ctrl, l10n),
                const SizedBox(height: DesignTokens.spacing4),
                _buildSpendingTrendCard(ctrl),
                const SizedBox(height: DesignTokens.spacing4),
                _buildGoalForecastsCard(ctrl, l10n),
                const SizedBox(height: DesignTokens.spacing4),
                _buildCategoryDistributionCard(ctrl, l10n),
                const SizedBox(height: DesignTokens.spacing4),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(InsightsController ctrl, AppLocalizations? l10n) {
    return Center(
      child: EmptyState(
        icon: Iconsax.warning_2,
        title: l10n?.failed_to_load_insights ?? 'Gagal memuat wawasan',
        subtitle: ctrl.errorMessage ?? 'Terjadi kesalahan',
        actionText: 'Coba Lagi',
        onAction: ctrl.refresh,
      ),
    );
  }

  Widget _buildHealthScoreCard(InsightsController ctrl) {
    final color = ctrl.getHealthScoreColor();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), DesignTokens.surfaceDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Iconsax.heart, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                'Skor Kesehatan Keuangan',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing5),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: ctrl.healthScore / 100,
                  strokeWidth: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ctrl.healthScore.toInt().toString(),
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ctrl.getHealthScoreLabel(),
                    style: GoogleFonts.poppins(color: color, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(InsightsController ctrl, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(color: DesignTokens.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.lamp_charge, color: DesignTokens.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Wawasan AI',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing3),
          if (ctrl.insights.isEmpty)
            Text(
              l10n?.no_insights_available ??
                  'Belum ada wawasan yang tersedia. Tambahkan lebih banyak transaksi untuk analisis.',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
            )
          else
            ...ctrl.insights.map((insight) => _buildInsightItem(insight)),
        ],
      ),
    );
  }

  Widget _buildInsightItem(Map<String, dynamic> insight) {
    Color iconColor;
    switch (insight['type']) {
      case 'positive':
        iconColor = DesignTokens.successColor;
        break;
      case 'warning':
        iconColor = Colors.orange;
        break;
      case 'danger':
        iconColor = DesignTokens.errorColor;
        break;
      default:
        iconColor = DesignTokens.primaryColor;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(insight['icon'] as IconData, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['title'] as String,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: DesignTokens.spacing1),
                Text(insight['description'] as String, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingTrendCard(InsightsController ctrl) {
    final trend = ctrl.spendingTrend;
    final direction = trend['direction']?.toString() ?? 'stable';
    final percentage = (trend['percentage'] as num?)?.toDouble() ?? 0;

    IconData trendIcon;
    Color trendColor;
    String label;

    switch (direction) {
      case 'increasing':
        trendIcon = Iconsax.arrow_up_1;
        trendColor = DesignTokens.errorColor;
        label = 'Meningkat ${percentage.toStringAsFixed(1)}%';
        break;
      case 'decreasing':
        trendIcon = Iconsax.arrow_down_1;
        trendColor = DesignTokens.successColor;
        label = 'Menurun ${percentage.toStringAsFixed(1)}%';
        break;
      default:
        trendIcon = Iconsax.minus;
        trendColor = Colors.grey;
        label = 'Stabil';
    }

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.chart, color: DesignTokens.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tren Pengeluaran',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing4),
          Row(
            children: [
              Icon(trendIcon, color: trendColor, size: 24),
              const SizedBox(width: 12),
              Text(label, style: GoogleFonts.poppins(color: trendColor, fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalForecastsCard(InsightsController ctrl, AppLocalizations? l10n) {
    if (ctrl.goals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(DesignTokens.spacing4),
        decoration: BoxDecoration(
          color: DesignTokens.surfaceDark,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(
          l10n?.no_financial_goals ?? 'Belum ada target keuangan. Tambahkan target untuk melihat proyeksi.',
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
        ),
      );
    }

    final forecaster = getIt<GoalForecastingService>();
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.flag, color: DesignTokens.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Proyeksi Target',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing3),
          ...ctrl.goals.take(3).map((goal) {
            final target = (goal['target_amount'] as num?)?.toDouble() ?? 0;
            final current = (goal['current_amount'] as num?)?.toDouble() ?? 0;
            final name = goal['goal_name']?.toString() ?? 'Target';
            final forecast = forecaster.forecastGoalCompletion(
              targetAmount: target,
              currentAmount: current,
              monthlyContribution: (goal['monthly_contribution'] as num?)?.toDouble() ?? 0,
            );
            final progress = target > 0 ? (current / target) * 100 : 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: DesignTokens.spacing2),
                  LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(DesignTokens.primaryColor),
                    minHeight: 6,
                  ),
                  const SizedBox(height: DesignTokens.spacing2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${progress.toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                          color: DesignTokens.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (forecast['monthsToCompletion'] != null && forecast['monthsToCompletion'] > 0)
                        Text(
                          '~${forecast['monthsToCompletion']} bulan lagi',
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                        ),
                    ],
                  ),
                  if (forecast['warning'] != null) ...[
                    const SizedBox(height: DesignTokens.spacing2),
                    Text(forecast['warning'] as String, style: GoogleFonts.poppins(color: Colors.orange, fontSize: 11)),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryDistributionCard(InsightsController ctrl, AppLocalizations? l10n) {
    final thisMonth =
        ctrl.transactions.where((t) {
          final dateStr = t['transaction_date']?.toString() ?? t['date']?.toString() ?? '';
          if (dateStr.isEmpty) return false;
          try {
            final date = DateTime.parse(dateStr);
            return date.year == DateTime.now().year && date.month == DateTime.now().month;
          } catch (_) {
            return false;
          }
        }).toList();

    final categorySpending = <String, double>{};
    for (final t in thisMonth) {
      if ((t['type']?.toString().toLowerCase() ?? 'expense') == 'expense') {
        final cat = t['category_name']?.toString() ?? 'Lainnya';
        categorySpending[cat] = (categorySpending[cat] ?? 0) + ((t['amount'] as num?)?.toDouble() ?? 0);
      }
    }

    if (categorySpending.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(DesignTokens.spacing4),
        decoration: BoxDecoration(
          color: DesignTokens.surfaceDark,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(
          l10n?.no_expenses_this_month ?? 'Belum ada pengeluaran bulan ini.',
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
        ),
      );
    }

    final sorted = categorySpending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.map((e) => e.value).reduce((a, b) => a + b);
    final colors = [
      DesignTokens.primaryColor,
      Colors.blue,
      DesignTokens.successColor,
      Colors.orange,
      Colors.red,
      Colors.cyan,
      Colors.pink,
      Colors.amber,
    ];

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.chart_2, color: DesignTokens.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Distribusi Kategori',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing4),
          ...sorted.take(5).toList().asMap().entries.map((entry) {
            final idx = entry.key;
            final category = entry.value.key;
            final amount = entry.value.value;
            final percentage = (amount / total) * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                          color: colors[idx % colors.length],
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spacing1),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(colors[idx % colors.length]),
                    minHeight: 6,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
