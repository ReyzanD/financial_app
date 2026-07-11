import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/features/cash_flow/presentation/controllers/cash_flow_controller.dart';

class CashFlowScreen extends StatefulWidget {
  const CashFlowScreen({super.key});

  @override
  State<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends State<CashFlowScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CashFlowController>().loadData();
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
                onRefresh: () => context.read<CashFlowController>().refresh(),
                child: Consumer<CashFlowController>(
                  builder: (context, ctrl, _) => _buildBody(context, l10n, ctrl),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations? l10n) {
    final ctrl = context.watch<CashFlowController>();
    final currentIncome = (ctrl.summary['current_month_income'] as num?)?.toDouble() ?? 0.0;
    final currentExpense = (ctrl.summary['current_month_expense'] as num?)?.toDouble() ?? 0.0;
    final currentNet = (ctrl.summary['current_month_net'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Iconsax.arrow_left, color: DesignTokens.textPrimaryDark),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Cash Flow',
                style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DesignTokens.surfaceDark,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              border: Border.all(color: DesignTokens.borderDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n?.this_month ?? 'Bulan Ini', style: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n?.income ?? 'Pemasukan', style: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark, fontSize: 11)),
                          Text(
                            CurrencyFormatter.formatRupiah(currentIncome.toInt()),
                            style: GoogleFonts.poppins(color: DesignTokens.successColor, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n?.expense ?? 'Pengeluaran', style: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark, fontSize: 11)),
                          Text(
                            CurrencyFormatter.formatRupiah(currentExpense.toInt()),
                            style: GoogleFonts.poppins(color: DesignTokens.errorColor, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Net', style: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark, fontSize: 11)),
                          Text(
                            CurrencyFormatter.formatRupiah(currentNet.toInt()),
                            style: GoogleFonts.poppins(
                              color: currentNet >= 0 ? DesignTokens.successColor : DesignTokens.errorColor,
                              fontSize: 14, fontWeight: FontWeight.w600,
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

  Widget _buildBody(BuildContext context, AppLocalizations? l10n, CashFlowController ctrl) {
    if (ctrl.isLoading) {
      return Center(child: CircularProgressIndicator(color: DesignTokens.primaryColor));
    }
    if (ctrl.errorMessage != null) {
      return _buildErrorState(context, l10n, ctrl);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWeeklyForecast(context, l10n, ctrl.weeklyForecast),
        const SizedBox(height: 16),
        _buildDailyForecast(context, l10n, ctrl.dailyForecast),
        const SizedBox(height: 16),
        _buildRiskWeeks(context, l10n, ctrl.weeklyForecast),
      ],
    );
  }

  Widget _buildWeeklyForecast(BuildContext context, AppLocalizations? l10n, Map<String, dynamic> weeklyForecast) {
    final forecast = (weeklyForecast['weekly_forecast'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (forecast.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weekly Forecast', style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...forecast.map((week) {
          final weekStart = week['week_start'] as DateTime? ?? DateTime.now();
          final projectedBalance = (week['projected_balance'] as num?)?.toDouble() ?? 0.0;
          final isLow = projectedBalance < 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignTokens.surfaceDark,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              border: Border.all(color: isLow ? DesignTokens.errorColor.withValues(alpha: 0.3) : DesignTokens.borderDark),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Week ${weekStart.day}/${weekStart.month}', style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark, fontSize: 13)),
                Text(
                  CurrencyFormatter.formatRupiah(projectedBalance.toInt()),
                  style: GoogleFonts.poppins(
                    color: isLow ? DesignTokens.errorColor : DesignTokens.successColor,
                    fontSize: 14, fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDailyForecast(BuildContext context, AppLocalizations? l10n, List<Map<String, dynamic>> dailyForecast) {
    if (dailyForecast.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daily Forecast (14 Days)', style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DesignTokens.surfaceDark,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            border: Border.all(color: DesignTokens.borderDark),
          ),
          child: Column(
            children: dailyForecast.take(7).map((day) {
              final date = day['date'] as DateTime? ?? DateTime.now();
              final projectedBalance = (day['projected_balance'] as num?)?.toDouble() ?? 0.0;
              final isWeekend = day['is_weekend'] as bool? ?? false;

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: DesignTokens.borderDark, width: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${date.day}/${date.month}',
                          style: GoogleFonts.poppins(
                            color: isWeekend ? DesignTokens.primaryColor : DesignTokens.textPrimaryDark,
                            fontSize: 12,
                          ),
                        ),
                        if (isWeekend) ...[
                          const SizedBox(width: 4),
                          Icon(Iconsax.calendar, size: 12, color: DesignTokens.primaryColor),
                        ],
                      ],
                    ),
                    Text(
                      CurrencyFormatter.formatRupiah(projectedBalance.toInt()),
                      style: GoogleFonts.poppins(
                        color: projectedBalance >= 0 ? DesignTokens.successColor : DesignTokens.errorColor,
                        fontSize: 13, fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskWeeks(BuildContext context, AppLocalizations? l10n, Map<String, dynamic> weeklyForecast) {
    final riskWeeks = (weeklyForecast['risk_weeks'] as num?)?.toInt() ?? 0;
    if (riskWeeks == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: DesignTokens.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.warning_2, color: DesignTokens.errorColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$riskWeeks risk weeks detected - projected negative balance',
              style: GoogleFonts.poppins(color: DesignTokens.errorColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations? l10n, CashFlowController ctrl) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2, size: 64, color: DesignTokens.errorColor),
          const SizedBox(height: 16),
          Text(
            l10n?.error ?? 'Terjadi kesalahan',
            style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(ctrl.errorMessage ?? '', style: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: ctrl.refresh,
            style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primaryColor),
            child: Text(l10n?.retry ?? 'Coba Lagi', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
