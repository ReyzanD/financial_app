import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/features/debts/presentation/controllers/debt_controller.dart';
import 'package:financial_app/features/debts/presentation/widgets/add_debt_modal.dart';
import 'package:financial_app/features/debts/presentation/widgets/record_payment_modal.dart';
import 'package:financial_app/models/debt_model.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<DebtController>().loadData());
  }

  Color _getDebtTypeColor(String type) {
    switch (type) {
      case 'credit_card':
        return Colors.red;
      case 'mortgage':
        return Colors.blue;
      case 'student':
        return Colors.green;
      case 'car':
        return Colors.orange;
      case 'personal':
        return Colors.purple;
      default:
        return DesignTokens.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<DebtController>();

    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l10n, controller),
            const OfflineIndicator(),
            Expanded(
              child: RefreshIndicator(
                color: DesignTokens.primaryColor,
                backgroundColor: DesignTokens.surfaceDark,
                onRefresh: controller.refresh,
                child: _buildBody(context, l10n, controller),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'debts_fab',
        backgroundColor: DesignTokens.primaryColor,
        onPressed: () => _showAddDebtModal(context),
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations? l10n,
    DebtController controller,
  ) {
    final totalDebt =
        (controller.summary['total_debt'] as num?)?.toDouble() ?? 0.0;

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
                l10n?.debt ?? 'Hutang',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textPrimaryDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                controller.activeOnly
                    ? l10n?.active ?? 'Aktif'
                    : l10n?.all ?? 'Semua',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
              Switch(
                value: controller.activeOnly,
                activeThumbColor: DesignTokens.primaryColor,
                inactiveThumbColor: DesignTokens.textTertiaryDark,
                inactiveTrackColor: DesignTokens.borderDark,
                onChanged: (_) => controller.toggleActiveOnly(),
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.total_debt ?? 'Total Hutang',
                        style: GoogleFonts.poppins(
                          color: DesignTokens.textSecondaryDark,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatRupiah(totalDebt.toInt()),
                        style: GoogleFonts.poppins(
                          color: DesignTokens.errorColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DesignTokens.errorColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
                  ),
                  child: const Icon(
                    Iconsax.money_send,
                    color: DesignTokens.errorColor,
                    size: 24,
                  ),
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
    DebtController controller,
  ) {
    if (controller.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryColor),
      );
    }
    if (controller.errorMessage != null) {
      return _buildErrorState(context, l10n, controller);
    }
    if (controller.debts.isEmpty) {
      return _buildEmptyState(context, l10n);
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      itemCount: controller.debts.length,
      itemBuilder: (context, index) {
        return _buildDebtCard(context, controller.debts[index], l10n);
      },
    );
  }

  Widget _buildDebtCard(
    BuildContext context,
    DebtModel debt,
    AppLocalizations? l10n,
  ) {
    final progress =
        debt.originalAmount > 0
            ? (debt.originalAmount - debt.currentBalance) / debt.originalAmount
            : 0.0;
    final percentage = (progress * 100).clamp(0, 100).toDouble();

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
                  color: _getDebtTypeColor(debt.type).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
                  ),
                ),
                child: Icon(
                  Iconsax.money_send,
                  color: _getDebtTypeColor(debt.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.name,
                      style: GoogleFonts.poppins(
                        color: DesignTokens.textPrimaryDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${l10n?.type ?? 'Tipe'}: ${_getDebtTypeLabel(debt.type)}',
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
                    CurrencyFormatter.formatRupiah(debt.currentBalance.toInt()),
                    style: GoogleFonts.poppins(
                      color: DesignTokens.errorColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${l10n?.interest ?? 'Bunga'}: ${debt.interestRate.toStringAsFixed(1)}%',
                    style: GoogleFonts.poppins(
                      color: DesignTokens.textTertiaryDark,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n?.original_amount ?? 'Awal'}: ${CurrencyFormatter.formatRupiah(debt.originalAmount.toInt())}',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textSecondaryDark,
                  fontSize: 11,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}% ${l10n?.progress ?? 'lunas'}',
                style: GoogleFonts.poppins(
                  color: DesignTokens.successColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: DesignTokens.borderDark,
              valueColor: AlwaysStoppedAnimation(DesignTokens.successColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () => _recordPayment(context, debt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.successColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusSmall,
                    ),
                  ),
                  child: Text(
                    l10n?.pay ?? 'Bayar',
                    style: GoogleFonts.poppins(
                      color: DesignTokens.successColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _deleteDebt(context, debt),
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

  String _getDebtTypeLabel(String type) {
    switch (type) {
      case 'credit_card':
        return 'Kartu Kredit';
      case 'mortgage':
        return 'Kredit Rumah';
      case 'student':
        return 'Pinjaman Pendidikan';
      case 'car':
        return 'Kredit Mobil';
      case 'personal':
        return 'Pinjaman Pribadi';
      default:
        return type;
    }
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations? l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.money_send,
            size: 64,
            color: DesignTokens.textTertiaryDark,
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.no_active_debts ?? 'Tidak ada hutang aktif',
            style: GoogleFonts.poppins(
              color: DesignTokens.textPrimaryDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.no_obligations_subtitle ?? 'Tap + untuk menambah hutang baru',
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    AppLocalizations? l10n,
    DebtController controller,
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
            controller.errorMessage ?? '',
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.refresh,
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

  void _showAddDebtModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => AddDebtModal(
            onDebtAdded: () => context.read<DebtController>().refresh(),
          ),
    );
  }

  void _recordPayment(BuildContext context, DebtModel debt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => RecordPaymentModal(
            debt: debt,
            onPaymentRecorded: () => context.read<DebtController>().refresh(),
          ),
    );
  }

  Future<void> _deleteDebt(BuildContext context, DebtModel debt) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
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
              l10n?.confirm_delete_budget ??
                  'Yakin ingin menghapus hutang ini?',
              style: GoogleFonts.poppins(
                color: DesignTokens.textSecondaryDark,
                fontSize: 13,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n?.cancel ?? 'Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
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
        await context.read<DebtController>().deleteDebt(debt.id);
        if (!mounted) return;
        ErrorHandlerService.showSuccessSnackbar(
          context,
          l10n?.debt_deleted ?? 'Hutang berhasil dihapus',
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
