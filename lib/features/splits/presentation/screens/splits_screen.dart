import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/features/splits/presentation/controllers/split_controller.dart';
import 'package:financial_app/features/splits/presentation/widgets/add_split_modal.dart';
import 'package:financial_app/models/split_model.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';

class SplitsScreen extends StatefulWidget {
  const SplitsScreen({super.key});
  @override
  State<SplitsScreen> createState() => _SplitsScreenState();
}

class _SplitsScreenState extends State<SplitsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<SplitController>().loadData());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.watch<SplitController>();
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
        heroTag: 'splits_fab',
        backgroundColor: DesignTokens.primaryColor,
        onPressed: () => _showAddModal(context),
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations? l10n,
    SplitController c,
  ) {
    final totalPending =
        (c.summary['total_pending'] as num?)?.toDouble() ?? 0.0;
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
                'Split',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textPrimaryDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                c.activeOnly
                    ? (l10n?.active ?? 'Aktif')
                    : (l10n?.all ?? 'Semua'),
                style: GoogleFonts.poppins(
                  color: DesignTokens.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
              Switch(
                value: c.activeOnly,
                activeThumbColor: DesignTokens.primaryColor,
                inactiveThumbColor: DesignTokens.textTertiaryDark,
                inactiveTrackColor: DesignTokens.borderDark,
                onChanged: (_) => c.toggleActiveOnly(),
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
                        'Total Tertunda',
                        style: GoogleFonts.poppins(
                          color: DesignTokens.textSecondaryDark,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatRupiah(totalPending.toInt()),
                        style: GoogleFonts.poppins(
                          color: DesignTokens.warningColor,
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
                    color: DesignTokens.warningColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
                  ),
                  child: const Icon(
                    Iconsax.money_recive,
                    color: DesignTokens.warningColor,
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
    SplitController c,
  ) {
    if (c.isLoading)
      return Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryColor),
      );
    if (c.errorMessage != null) return _buildError(context, l10n, c);
    if (c.splits.isEmpty) return _buildEmpty(context, l10n);
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      itemCount: c.splits.length,
      itemBuilder: (ctx, i) => _buildCard(c.splits[i]),
    );
  }

  Widget _buildCard(SplitModel split) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(color: DesignTokens.borderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DesignTokens.warningColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            ),
            child: const Icon(
              Iconsax.money_recive,
              color: DesignTokens.warningColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  split.participantName,
                  style: GoogleFonts.poppins(
                    color: DesignTokens.textPrimaryDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  split.notes?.isNotEmpty == true
                      ? split.notes!
                      : split.participantPhone.isNotEmpty
                          ? split.participantPhone
                          : split.participantName,
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
                CurrencyFormatter.formatRupiah(split.amount.toInt()),
                style: GoogleFonts.poppins(
                  color:
                      split.isSettled
                          ? DesignTokens.successColor
                          : DesignTokens.warningColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                split.isSettled ? 'Lunas' : 'Tertunda',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textTertiaryDark,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _delete(context, split),
            child: const Icon(
              Iconsax.trash,
              size: 16,
              color: DesignTokens.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, AppLocalizations? l10n) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Iconsax.money_recive,
          size: 64,
          color: DesignTokens.textTertiaryDark,
        ),
        const SizedBox(height: 16),
        Text(
          l10n?.no_splits ?? 'Belum ada split',
          style: GoogleFonts.poppins(
            color: DesignTokens.textPrimaryDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap + untuk menambah split baru',
          style: GoogleFonts.poppins(
            color: DesignTokens.textSecondaryDark,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => _showAddModal(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            ),
          ),
          child: Text(
            l10n?.add_split ?? 'Buat Split',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildError(
    BuildContext context,
    AppLocalizations? l10n,
    SplitController c,
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
          (ctx) => AddSplitModal(
            onSplitAdded: () => context.read<SplitController>().refresh(),
          ),
    );
  }

  Future<void> _delete(BuildContext context, SplitModel split) async {
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
              l10n?.delete_split_confirm ?? 'Yakin ingin menghapus split ini?',
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
        await context.read<SplitController>().deleteSplit(split.id);
        if (!mounted) return;
        ErrorHandlerService.showSuccessSnackbar(
          context,
          l10n?.split_deleted_successfully ?? 'Split berhasil dihapus',
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
