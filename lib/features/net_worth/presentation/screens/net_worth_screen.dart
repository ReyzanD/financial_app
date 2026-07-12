import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/features/net_worth/presentation/controllers/net_worth_controller.dart';

class NetWorthScreen extends StatefulWidget {
  const NetWorthScreen({super.key});

  @override
  State<NetWorthScreen> createState() => _NetWorthScreenState();
}

class _NetWorthScreenState extends State<NetWorthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NetWorthController>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l10n),
            const OfflineIndicator(),
            Expanded(
              child: RefreshIndicator(
                color: DesignTokens.primaryColor,
                backgroundColor: DesignTokens.surfaceDark,
                onRefresh: () => context.read<NetWorthController>().refresh(),
                child: Consumer<NetWorthController>(
                  builder:
                      (context, ctrl, _) => _buildBody(context, l10n, ctrl),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Consumer<NetWorthController>(
        builder:
            (context, ctrl, _) => FloatingActionButton(
              heroTag: 'net_worth_fab',
              backgroundColor: DesignTokens.primaryColor,
              onPressed: () => _recordSnapshot(context),
              child: const Icon(Iconsax.add, color: Colors.white),
            ),
      ),
    );
  }

  Future<void> _recordSnapshot(BuildContext context) async {
    try {
      await context.read<NetWorthController>().recordSnapshot();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ErrorHandlerService.showSuccessSnackbar(
        context,
        l10n?.snapshot_recorded ?? 'Snapshot recorded',
      );
    } catch (e) {
      if (!mounted) return;
      ErrorHandlerService.showErrorSnackbar(
        context,
        ErrorHandlerService.getUserFriendlyMessage(e),
      );
    }
  }

  Widget _buildHeader(BuildContext context, AppLocalizations? l10n) {
    final ctrl = context.watch<NetWorthController>();
    final netWorth = (ctrl.data['net_worth'] as num?)?.toDouble() ?? 0.0;
    final totalAssets = (ctrl.data['total_assets'] as num?)?.toDouble() ?? 0.0;
    final totalLiabilities =
        (ctrl.data['total_liabilities'] as num?)?.toDouble() ?? 0.0;
    final trend = ctrl.trend['trend'] ?? 'neutral';
    final change = (ctrl.trend['change'] as num?)?.toDouble() ?? 0.0;
    final isPositive = trend == 'up' || change > 0;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Iconsax.arrow_left,
                  color: DesignTokens.textPrimaryDark,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Net Worth',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textPrimaryDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (isPositive
                          ? DesignTokens.successColor
                          : DesignTokens.errorColor)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Iconsax.arrow_up_1 : Iconsax.arrow_down,
                      color:
                          isPositive
                              ? DesignTokens.successColor
                              : DesignTokens.errorColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${change.toStringAsFixed(1)}%',
                      style: GoogleFonts.poppins(
                        color:
                            isPositive
                                ? DesignTokens.successColor
                                : DesignTokens.errorColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacing4),
            decoration: BoxDecoration(
              color: DesignTokens.surfaceDark,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              border: Border.all(color: DesignTokens.borderDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Net Worth',
                  style: GoogleFonts.poppins(
                    color: DesignTokens.textSecondaryDark,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatRupiah(netWorth.toInt()),
                  style: GoogleFonts.poppins(
                    color:
                        netWorth >= 0
                            ? DesignTokens.successColor
                            : DesignTokens.errorColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assets',
                            style: GoogleFonts.poppins(
                              color: DesignTokens.textSecondaryDark,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatRupiah(totalAssets.toInt()),
                            style: GoogleFonts.poppins(
                              color: DesignTokens.textPrimaryDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Liabilities',
                            style: GoogleFonts.poppins(
                              color: DesignTokens.textSecondaryDark,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatRupiah(
                              totalLiabilities.toInt(),
                            ),
                            style: GoogleFonts.poppins(
                              color: DesignTokens.errorColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

  Widget _buildBody(
    BuildContext context,
    AppLocalizations? l10n,
    NetWorthController ctrl,
  ) {
    if (ctrl.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryColor),
      );
    }
    if (ctrl.errorMessage != null) {
      return _buildErrorState(context, l10n, ctrl);
    }
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      children: [
        _buildBreakdown(context, l10n, ctrl.data),
        const SizedBox(height: 16),
        _buildHistory(context, l10n, ctrl.history),
      ],
    );
  }

  Widget _buildBreakdown(
    BuildContext context,
    AppLocalizations? l10n,
    Map<String, dynamic> data,
  ) {
    final assetBreakdown =
        (data['asset_breakdown'] as Map?)?.cast<String, double>() ?? {};
    final liabilityBreakdown =
        (data['liability_breakdown'] as Map?)?.cast<String, double>() ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Breakdown',
          style: GoogleFonts.poppins(
            color: DesignTokens.textPrimaryDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (assetBreakdown.isNotEmpty) ...[
          Text(
            'Assets',
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ...assetBreakdown.entries.map(
            (entry) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DesignTokens.surfaceDark,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                border: Border.all(color: DesignTokens.borderDark),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getAssetTypeLabel(entry.key),
                    style: GoogleFonts.poppins(
                      color: DesignTokens.textPrimaryDark,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatRupiah(entry.value.toInt()),
                    style: GoogleFonts.poppins(
                      color: DesignTokens.successColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (liabilityBreakdown.isNotEmpty) ...[
          Text(
            'Liabilities',
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ...liabilityBreakdown.entries.map(
            (entry) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DesignTokens.surfaceDark,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                border: Border.all(color: DesignTokens.borderDark),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getLiabilityTypeLabel(entry.key),
                    style: GoogleFonts.poppins(
                      color: DesignTokens.textPrimaryDark,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatRupiah(entry.value.toInt()),
                    style: GoogleFonts.poppins(
                      color: DesignTokens.errorColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHistory(
    BuildContext context,
    AppLocalizations? l10n,
    List<Map<String, dynamic>> history,
  ) {
    if (history.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend',
            style: GoogleFonts.poppins(
              color: DesignTokens.textPrimaryDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: DesignTokens.surfaceDark,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              border: Border.all(color: DesignTokens.borderDark),
            ),
            child: Column(
              children: [
                Icon(
                  Iconsax.chart,
                  size: 48,
                  color: DesignTokens.textSecondaryDark.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.chart_placeholder ?? 'Grafik akan tersedia setelah beberapa periode',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: DesignTokens.textSecondaryDark,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trend',
          style: GoogleFonts.poppins(
            color: DesignTokens.textPrimaryDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacing4),
          decoration: BoxDecoration(
            color: DesignTokens.surfaceDark,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            border: Border.all(color: DesignTokens.borderDark),
          ),
          child: Column(
            children: [
              // Trend line chart
              SizedBox(
                height: 180,
                child: _buildTrendChart(
                  history.take(12).toList().reversed.toList(),
                ),
              ),
              const Divider(color: DesignTokens.borderDark, height: 24),
              // Compact list below chart
              ...history.take(5).map((snapshot) {
                final date = snapshot['snapshot_date'] ?? '';
                final netWorth =
                    (snapshot['net_worth'] as num?)?.toDouble() ?? 0.0;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: DesignTokens.borderDark,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        date,
                        style: GoogleFonts.poppins(
                          color: DesignTokens.textSecondaryDark,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatRupiah(netWorth.toInt()),
                        style: GoogleFonts.poppins(
                          color:
                              netWorth >= 0
                                  ? DesignTokens.successColor
                                  : DesignTokens.errorColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendChart(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < history.length; i++) {
      final value = (history[i]['net_worth'] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), value));
      if (value < minY) minY = value;
      if (value > maxY) maxY = value;
    }

    final yPadding = (maxY - minY) * 0.15;
    if (yPadding == 0) {
      minY -= 1000;
      maxY += 1000;
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine:
              (value) => FlLine(
                color: DesignTokens.borderDark.withValues(alpha: 0.3),
                strokeWidth: 1,
              ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget:
                  (value, meta) => Text(
                    CurrencyFormatter.formatRupiah(value.toInt()),
                    style: GoogleFonts.poppins(
                      color: DesignTokens.textSecondaryDark,
                      fontSize: 9,
                    ),
                  ),
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const SizedBox.shrink(),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= history.length)
                  return const SizedBox.shrink();
                final dateStr = history[idx]['snapshot_date'] as String? ?? '';
                // Show month-day only
                final shortDate =
                    dateStr.length >= 10 ? dateStr.substring(5, 10) : dateStr;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    shortDate,
                    style: GoogleFonts.poppins(
                      color: DesignTokens.textSecondaryDark,
                      fontSize: 8,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: minY - yPadding,
        maxY: maxY + yPadding,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: DesignTokens.primaryColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: spots.length <= 12,
              getDotPainter:
                  (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 3,
                    color: DesignTokens.primaryColor,
                    strokeWidth: 1.5,
                    strokeColor: Colors.white,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: DesignTokens.primaryColor.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems:
                (touchedSpots) =>
                    touchedSpots.map((spot) {
                      final value = CurrencyFormatter.formatRupiah(
                        spot.y.toInt(),
                      );
                      return LineTooltipItem(
                        value,
                        TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
          ),
        ),
      ),
    );
  }

  String _getAssetTypeLabel(String type) {
    switch (type) {
      case 'cash':
        return 'Cash';
      case 'bank':
        return 'Bank';
      case 'e_wallet':
        return 'E-Wallet';
      case 'investments':
        return 'Investments';
      default:
        return type;
    }
  }

  String _getLiabilityTypeLabel(String type) {
    switch (type) {
      case 'personal':
        return 'Pinjaman Pribadi';
      case 'mortgage':
        return 'Kredit Rumah';
      case 'student':
        return 'Pinjaman Pendidikan';
      case 'credit_card':
        return 'Kartu Kredit';
      case 'car':
        return 'Kredit Mobil';
      default:
        return type;
    }
  }

  Widget _buildErrorState(
    BuildContext context,
    AppLocalizations? l10n,
    NetWorthController ctrl,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2, size: 64, color: DesignTokens.errorColor),
          const SizedBox(height: 16),
          Text(
            l10n?.error ?? 'Terjadi kesalahan',
            style: GoogleFonts.poppins(
              color: DesignTokens.textPrimaryDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ctrl.errorMessage ?? '',
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: ctrl.refresh,
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primaryColor,
            ),
            child: Text(
              l10n?.retry ?? 'Coba Lagi',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
