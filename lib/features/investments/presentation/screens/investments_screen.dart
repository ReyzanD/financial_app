import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/features/investments/presentation/controllers/investment_controller.dart';
import 'package:financial_app/features/investments/presentation/widgets/add_investment_modal.dart';
import 'package:financial_app/models/investment_model.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});
  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<InvestmentController>().loadData());
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'stock':
        return Colors.blue;
      case 'mutual_fund':
        return Colors.green;
      case 'crypto':
        return Colors.orange;
      case 'bond':
        return Colors.purple;
      case 'gold':
        return Colors.amber;
      default:
        return DesignTokens.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.watch<InvestmentController>();
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l10n, c),
            const OfflineIndicator(),
            Expanded(
              child: RefreshIndicator(
                color: DesignTokens.primaryColor,
                backgroundColor: DesignTokens.surfaceDark,
                onRefresh: c.refresh,
                child: _buildBody(context, l10n, c),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'investments_fab',
        backgroundColor: DesignTokens.primaryColor,
        onPressed: () => _showAddModal(context),
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations? l10n,
    InvestmentController c,
  ) {
    final totalValue = (c.summary['total_value'] as num?)?.toDouble() ?? 0.0;
    final totalPnL = (c.summary['total_pnl'] as num?)?.toDouble() ?? 0.0;
    final pnlPct = (c.summary['pnl_percentage'] as num?)?.toDouble() ?? 0.0;
    final positive = totalPnL >= 0;

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
              Semantics(
                header: true,
                child: Text(
                  l10n?.investment ?? 'Investasi',
                  style: GoogleFonts.poppins(
                    color: DesignTokens.textPrimaryDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
                  l10n?.total_amount ?? 'Total Nilai Portofolio',
                  style: GoogleFonts.poppins(
                    color: DesignTokens.textSecondaryDark,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatRupiah(totalValue.toInt()),
                  style: GoogleFonts.poppins(
                    color: DesignTokens.textPrimaryDark,
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
                            'P&L',
                            style: GoogleFonts.poppins(
                              color: DesignTokens.textSecondaryDark,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '${positive ? '+' : ''}${CurrencyFormatter.formatRupiah(totalPnL.toInt())}',
                            style: GoogleFonts.poppins(
                              color:
                                  positive
                                      ? DesignTokens.successColor
                                      : DesignTokens.errorColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (positive
                                ? DesignTokens.successColor
                                : DesignTokens.errorColor)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusSmall,
                        ),
                      ),
                      child: Text(
                        '${positive ? '+' : ''}${pnlPct.toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                          color:
                              positive
                                  ? DesignTokens.successColor
                                  : DesignTokens.errorColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
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
    InvestmentController c,
  ) {
    if (c.isLoading)
      return Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryColor),
      );
    if (c.errorMessage != null) return _buildError(context, l10n, c);
    if (c.investments.isEmpty) return _buildEmpty(context, l10n);
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      itemCount: c.investments.length,
      itemBuilder: (context, i) => _buildCard(c.investments[i], l10n),
    );
  }

  Widget _buildCard(InvestmentModel inv, AppLocalizations? l10n) {
    final totalCost = inv.quantity * inv.buyPrice;
    final totalValue = inv.quantity * inv.currentPrice;
    final pnl = totalValue - totalCost;
    final pnlPct = totalCost > 0 ? (pnl / totalCost) * 100 : 0.0;
    final positive = pnl >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(DesignTokens.spacing4),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getTypeColor(inv.type).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
                  ),
                ),
                child: Icon(
                  Iconsax.chart_success,
                  color: _getTypeColor(inv.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.name,
                      style: GoogleFonts.poppins(
                        color: DesignTokens.textPrimaryDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_getTypeLabel(inv.type)} • ${inv.quantity.toStringAsFixed(2)} unit',
                      style: GoogleFonts.poppins(
                        color: DesignTokens.textSecondaryDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatRupiah(totalValue.toInt()),
                    style: GoogleFonts.poppins(
                      color: DesignTokens.textPrimaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        positive ? Iconsax.arrow_up_1 : Iconsax.arrow_down,
                        size: 12,
                        color:
                            positive
                                ? DesignTokens.successColor
                                : DesignTokens.errorColor,
                      ),
                      Text(
                        '${pnlPct.toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                          color:
                              positive
                                  ? DesignTokens.successColor
                                  : DesignTokens.errorColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _detail(
                'Harga Beli',
                CurrencyFormatter.formatRupiah(inv.buyPrice.toInt()),
              ),
              _detail(
                l10n?.current_balance ?? 'Harga Saat Ini',
                CurrencyFormatter.formatRupiah(inv.currentPrice.toInt()),
              ),
              _detail(
                'P&L',
                '${positive ? '+' : ''}${CurrencyFormatter.formatRupiah(pnl.toInt())}',
                valueColor:
                    positive
                        ? DesignTokens.successColor
                        : DesignTokens.errorColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () => _delete(context, inv),
                child: const Icon(
                  Iconsax.trash,
                  size: 16,
                  color: DesignTokens.errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value, {Color? valueColor}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.poppins(
          color: DesignTokens.textTertiaryDark,
          fontSize: 11,
        ),
      ),
      Text(
        value,
        style: GoogleFonts.poppins(
          color: valueColor ?? DesignTokens.textSecondaryDark,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  String _getTypeLabel(String type) {
    switch (type) {
      case 'stock':
        return 'Saham';
      case 'mutual_fund':
        return 'Reksa Dana';
      case 'crypto':
        return 'Kripto';
      case 'bond':
        return 'Obligasi';
      case 'gold':
        return 'Emas';
      default:
        return type;
    }
  }

  Widget _buildEmpty(BuildContext context, AppLocalizations? l10n) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Iconsax.chart_success,
          size: 64,
          color: DesignTokens.textTertiaryDark,
        ),
        const SizedBox(height: 16),
        Text(
          l10n?.no_investments ?? 'Belum ada investasi',
          style: GoogleFonts.poppins(
            color: DesignTokens.textPrimaryDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap + untuk menambah investasi baru',
          style: GoogleFonts.poppins(
            color: DesignTokens.textSecondaryDark,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );

  Widget _buildError(
    BuildContext context,
    AppLocalizations? l10n,
    InvestmentController c,
  ) => Center(
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
          c.errorMessage ?? '',
          style: GoogleFonts.poppins(
            color: DesignTokens.textSecondaryDark,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: c.refresh,
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

  void _showAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => AddInvestmentModal(
            onInvestmentAdded:
                () => context.read<InvestmentController>().refresh(),
          ),
    );
  }

  Future<void> _delete(BuildContext context, InvestmentModel inv) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: DesignTokens.surfaceDark,
            title: Text(
              l10n?.delete ?? 'Hapus',
              style: GoogleFonts.poppins(
                color: DesignTokens.textPrimaryDark,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              l10n?.delete_investment_confirm ??
                  'Yakin ingin menghapus investasi ini?',
              style: GoogleFonts.poppins(
                color: DesignTokens.textSecondaryDark,
                fontSize: 13,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n?.cancel ?? 'Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  l10n?.delete ?? 'Hapus',
                  style: const TextStyle(color: DesignTokens.errorColor),
                ),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      try {
        await context.read<InvestmentController>().deleteInvestment(inv.id);
        if (!mounted) return;
        ErrorHandlerService.showSuccessSnackbar(
          context,
          l10n?.investment_deleted_successfully ?? 'Investasi berhasil dihapus',
        );
      } catch (e) {
        if (!mounted) return;
        ErrorHandlerService.showErrorSnackbar(
          context,
          ErrorHandlerService.getUserFriendlyMessage(e),
        );
      }
    }
  }
}
