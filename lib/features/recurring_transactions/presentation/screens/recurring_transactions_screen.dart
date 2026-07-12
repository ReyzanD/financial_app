import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/features/recurring_transactions/presentation/controllers/recurring_transaction_controller.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecurringTransactionController>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n?.recurring_transactions ?? 'Transaksi Berulang',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Consumer<RecurringTransactionController>(
            builder:
                (context, ctrl, _) => IconButton(
                  icon: Icon(
                    ctrl.showActiveOnly ? Iconsax.eye : Iconsax.eye_slash,
                    color: Colors.white,
                  ),
                  onPressed: ctrl.toggleFilter,
                  tooltip:
                      ctrl.showActiveOnly
                          ? 'Tampilkan Semua'
                          : 'Tampilkan Aktif',
                ),
          ),
          Consumer<RecurringTransactionController>(
            builder:
                (context, ctrl, _) => IconButton(
                  icon: const Icon(Iconsax.refresh, color: Colors.white),
                  onPressed: ctrl.refresh,
                  tooltip: 'Muat Ulang',
                ),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: Consumer<RecurringTransactionController>(
              builder: (context, ctrl, _) {
                if (ctrl.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: DesignTokens.primaryColor,
                    ),
                  );
                }
                if (ctrl.transactions.isEmpty) {
                  return _buildEmptyState(context);
                }
                return _buildTransactionsList(context, ctrl);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'recurring_fab',
        onPressed: () {
          ErrorHandlerService.showInfoSnackbar(
            context,
            l10n?.feature_coming_soon ??
                'Fitur transaksi berulang akan segera hadir',
          );
        },
        backgroundColor: DesignTokens.primaryColor,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.repeat, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            l10n?.no_recurring_transactions ?? 'Belum ada transaksi berulang',
            style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)?.tap_plus_to_create ??
                'Tap tombol + untuk membuat',
            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(
    BuildContext context,
    RecurringTransactionController ctrl,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      itemCount: ctrl.transactions.length,
      itemBuilder:
          (context, index) =>
              _buildTransactionCard(context, ctrl.transactions[index], ctrl),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    Map<String, dynamic> transaction,
    RecurringTransactionController ctrl,
  ) {
    final l10n = AppLocalizations.of(context);
    // Read from suffixed DB keys with clean fallback
    final type =
        (transaction['type_232143'] ?? transaction['type'])
            ?.toString()
            .toLowerCase() ??
        'expense';
    final amount =
        ((transaction['amount_232143'] ?? transaction['amount']) as num?)
            ?.toDouble() ??
        0.0;
    final description =
        (transaction['description_232143'] ?? transaction['description'])
            ?.toString() ??
        (l10n?.transaction ?? 'Transaksi');
    final frequency =
        (transaction['frequency_232143'] ??
                transaction['frequency'] ??
                transaction['recurring_pattern_232143'])
            ?.toString() ??
        'monthly';
    final isActive =
        (transaction['is_active_232143'] ?? transaction['is_active']) == true;
    final nextDate =
        transaction['next_date_232143'] ?? transaction['next_date'];

    final typeColor = _getTypeColor(type);
    final typeIcon = _getTypeIcon(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(
          color:
              isActive
                  ? typeColor.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                ),
                child: Icon(typeIcon, color: typeColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            description,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Dijeda',
                              style: GoogleFonts.poppins(
                                color: Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.primaryColor.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Iconsax.repeat,
                                size: 10,
                                color: DesignTokens.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getFrequencyText(frequency, l10n),
                                style: GoogleFonts.poppins(
                                  color: DesignTokens.primaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (nextDate != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Berikutnya: $nextDate',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    type == 'income'
                        ? '+${CurrencyFormatter.formatRupiah(amount)}'
                        : '-${CurrencyFormatter.formatRupiah(amount)}',
                    style: GoogleFonts.poppins(
                      color: typeColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: isActive ? Iconsax.pause : Iconsax.play,
                  label:
                      isActive
                          ? (l10n?.pause ?? 'Jeda')
                          : (l10n?.resume ?? 'Lanjut'),
                  color: isActive ? Colors.orange : Colors.green,
                  onTap: () => _togglePause(context, ctrl, transaction),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Iconsax.edit,
                  label: 'Edit',
                  color: Colors.blue,
                  onTap:
                      () => ErrorHandlerService.showWarningSnackbar(
                        context,
                        l10n?.edit_feature_coming_soon ??
                            'Fitur edit segera hadir',
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Iconsax.trash,
                  label: l10n?.delete_label ?? 'Hapus',
                  color: Colors.red,
                  onTap: () => _deleteTransaction(context, ctrl, transaction),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePause(
    BuildContext context,
    RecurringTransactionController ctrl,
    Map<String, dynamic> transaction,
  ) async {
    try {
      await ctrl.togglePause(transaction);
      if (!mounted) return;
      final isActive = transaction['is_active'] == true;
      if (isActive) {
        ErrorHandlerService.showWarningSnackbar(
          context,
          AppLocalizations.of(context)?.transaction_paused ??
              'Transaksi dijeda',
        );
      } else {
        ErrorHandlerService.showSuccessSnackbar(
          context,
          AppLocalizations.of(context)?.transaction_resumed ??
              'Transaksi dilanjutkan',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandlerService.showErrorSnackbar(
        context,
        '${AppLocalizations.of(context)?.failed ?? 'Gagal'}: ${ErrorHandlerService.getUserFriendlyMessage(e)}',
      );
    }
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    RecurringTransactionController ctrl,
    Map<String, dynamic> transaction,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: DesignTokens.surfaceDark,
            title: Text(
              l10n?.delete_recurring_transaction_title ??
                  'Hapus Transaksi Berulang?',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: Text(
              '${l10n?.transactions ?? 'Transaksi'} "${transaction['description']}" ${l10n?.delete_recurring_transaction_message ?? 'akan dihapus permanen.'}',
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  l10n?.cancel ?? 'Batal',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  l10n?.delete_label ?? 'Hapus',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      try {
        await ctrl.deleteTransaction(transaction['id'].toString());
        if (!mounted) return;
        ErrorHandlerService.showSuccessSnackbar(
          context,
          l10n?.transaction_deleted_successfully ??
              'Transaksi berhasil dihapus',
        );
      } catch (e) {
        if (!mounted) return;
        ErrorHandlerService.showErrorSnackbar(
          context,
          '${l10n?.failed ?? 'Gagal'}: ${ErrorHandlerService.getUserFriendlyMessage(e)}',
        );
      }
    }
  }

  String _getFrequencyText(String frequency, AppLocalizations? l10n) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return l10n?.daily ?? 'Harian';
      case 'weekly':
        return l10n?.weekly ?? 'Mingguan';
      case 'monthly':
        return l10n?.monthly ?? 'Bulanan';
      case 'yearly':
        return l10n?.yearly ?? 'Tahunan';
      default:
        return frequency;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return Colors.green;
      case 'expense':
        return Colors.red;
      case 'transfer':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return Iconsax.arrow_down_1;
      case 'expense':
        return Iconsax.arrow_up_3;
      case 'transfer':
        return Iconsax.repeat;
      default:
        return Iconsax.wallet_3;
    }
  }
}
