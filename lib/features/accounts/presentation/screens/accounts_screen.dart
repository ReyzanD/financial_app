import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/features/accounts/presentation/controllers/account_controller.dart';
import 'package:financial_app/features/accounts/presentation/widgets/add_account_modal.dart';
import 'package:financial_app/models/account_model.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AccountController>().loadData();
    });
  }

  Color _getAccountColor(String? color) {
    if (color == null || color.isEmpty) return DesignTokens.primaryColor;
    try {
      return Color(int.parse(color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return DesignTokens.primaryColor;
    }
  }

  IconData _getAccountIcon(String? icon) {
    switch (icon ?? 'wallet') {
      case 'wallet':
        return Iconsax.wallet;
      case 'account_balance':
        return Iconsax.bank;
      case 'phone_android':
        return Iconsax.mobile;
      default:
        return Iconsax.wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<AccountController>();

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
        heroTag: 'accounts_fab',
        backgroundColor: DesignTokens.primaryColor,
        onPressed: () => _showAddAccountModal(context),
        tooltip: l10n?.add_account ?? 'Tambah Akun',
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations? l10n,
    AccountController controller,
  ) {
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
                tooltip: 'Kembali',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Semantics(
                header: true,
                child: Text(
                  l10n?.account ?? 'Akun',
                  style: GoogleFonts.poppins(
                    color: DesignTokens.textPrimaryDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Saldo',
                  style: GoogleFonts.poppins(
                    color: DesignTokens.textSecondaryDark,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatRupiah(
                    controller.totalBalance.toInt(),
                  ),
                  style: GoogleFonts.poppins(
                    color: DesignTokens.textPrimaryDark,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (controller.balanceByType.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children:
                        controller.balanceByType.entries.map((entry) {
                          return Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getTypeLabel(entry.key),
                                  style: GoogleFonts.poppins(
                                    color: DesignTokens.textTertiaryDark,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatRupiah(
                                    entry.value.toInt(),
                                  ),
                                  style: GoogleFonts.poppins(
                                    color: DesignTokens.textSecondaryDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'cash':
        return 'Cash';
      case 'bank':
        return 'Bank';
      case 'e_wallet':
        return 'E-Wallet';
      default:
        return type;
    }
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations? l10n,
    AccountController controller,
  ) {
    if (controller.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryColor),
      );
    }

    if (controller.errorMessage != null) {
      return _buildErrorState(context, l10n, controller);
    }

    if (controller.accounts.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      itemCount: controller.accounts.length,
      itemBuilder: (context, index) {
        final account = controller.accounts[index];
        return _buildAccountCard(context, l10n, account, controller);
      },
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    AppLocalizations? l10n,
    AccountModel account,
    AccountController controller,
  ) {
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getAccountColor(account.color).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            ),
            child: Icon(
              _getAccountIcon(account.icon),
              color: _getAccountColor(account.color),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: GoogleFonts.poppins(
                    color: DesignTokens.textPrimaryDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _getTypeLabel(account.type),
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
                CurrencyFormatter.formatRupiah(account.balance.toInt()),
                style: GoogleFonts.poppins(
                  color: DesignTokens.successColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    label: l10n?.edit_account ?? 'Edit akun',
                    button: true,
                    child: InkWell(
                      onTap: () => _editAccount(context, account),
                      child: Icon(
                        Iconsax.edit,
                        size: 16,
                        color: DesignTokens.textSecondaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    label: l10n?.delete_account ?? 'Hapus akun',
                    button: true,
                    child: InkWell(
                      onTap: () => _deleteAccount(context, account, controller),
                      child: Icon(
                        Iconsax.trash,
                        size: 16,
                        color: DesignTokens.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations? l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.wallet, size: 64, color: DesignTokens.textTertiaryDark),
          const SizedBox(height: 16),
          Text(
            l10n?.no_accounts ?? 'Belum Ada Akun',
            style: GoogleFonts.poppins(
              color: DesignTokens.textPrimaryDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.no_transactions_subtitle ?? 'Tap + untuk menambah akun baru',
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
    AccountController controller,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2, size: 64, color: DesignTokens.errorColor),
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(
              l10n?.error ?? 'Terjadi kesalahan',
              style: GoogleFonts.poppins(
                color: DesignTokens.textPrimaryDark,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              controller.errorMessage ?? '',
              style: GoogleFonts.poppins(
                color: DesignTokens.textSecondaryDark,
                fontSize: 14,
              ),
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

  void _showAddAccountModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AddAccountModal(
          onAccountAdded: () => context.read<AccountController>().refresh(),
        );
      },
    );
  }

  void _editAccount(BuildContext context, AccountModel account) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AddAccountModal(
          account: account,
          onAccountAdded: () => context.read<AccountController>().refresh(),
        );
      },
    );
  }

  Future<void> _deleteAccount(
    BuildContext context,
    AccountModel account,
    AccountController controller,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
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
            l10n?.confirm_delete_budget ?? 'Yakin ingin menghapus akun ini?',
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
        );
      },
    );

    if (confirmed == true) {
      try {
        await controller.deleteAccount(account.id);
        if (!mounted) return;
        ErrorHandlerService.showSuccessSnackbar(
          context,
          l10n?.account_deleted_successfully ?? 'Akun berhasil dihapus',
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
