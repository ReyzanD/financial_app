import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/models/account_model.dart';
import 'package:financial_app/services/data/account_data_service.dart';
import 'package:financial_app/utils/design_tokens.dart';

class AccountSection extends StatefulWidget {
  final String? selectedAccountId;
  final Function(String?) onAccountSelected;

  const AccountSection({
    super.key,
    this.selectedAccountId,
    required this.onAccountSelected,
  });

  @override
  State<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<AccountSection> {
  final AccountDataService _accountData = getIt<AccountDataService>();
  List<AccountModel> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _accountData.getAccounts();
      if (mounted) {
        setState(() {
          _accounts = accounts;
          _isLoading = false;
        });
        // Auto-select default account if none selected
        if (widget.selectedAccountId == null && accounts.isNotEmpty) {
          final defaultAccount = accounts.firstWhere(
            (a) => a.isDefault,
            orElse: () => accounts.first,
          );
          widget.onAccountSelected(defaultAccount.id);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  IconData _getAccountIcon(String type) {
    switch (type) {
      case 'cash':
        return Iconsax.money;
      case 'bank':
        return Iconsax.bank;
      case 'e_wallet':
        return Iconsax.wallet;
      case 'credit_card':
        return Iconsax.card;
      case 'investment':
        return Iconsax.graph;
      default:
        return Iconsax.wallet_1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.account ?? 'Akun',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: CircularProgressIndicator(color: DesignTokens.primaryColor),
          ),
        ],
      );
    }

    if (_accounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.account ?? 'Akun',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            GestureDetector(
              onTap: () => widget.onAccountSelected(null),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      widget.selectedAccountId == null
                          ? DesignTokens.primaryColor.withValues(alpha: 0.3)
                          : DesignTokens.surfaceDark,
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
                  ),
                  border: Border.all(
                    color:
                        widget.selectedAccountId == null
                            ? DesignTokens.primaryColor
                            : Colors.grey[700]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.global,
                      size: 18,
                      color:
                          widget.selectedAccountId == null
                              ? DesignTokens.primaryColor
                              : Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n?.all ?? 'Semua',
                      style: GoogleFonts.poppins(
                        color:
                            widget.selectedAccountId == null
                                ? DesignTokens.primaryColor
                                : Colors.grey[500],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ..._accounts.map((account) {
              final isSelected = widget.selectedAccountId == account.id;
              final type = account.type;
              final name = account.name;
              final colorHex = account.color ?? '#8B5FBF';
              final accountColor = Color(
                int.parse(colorHex.replaceFirst('#', '0xFF')),
              );

              return GestureDetector(
                onTap: () => widget.onAccountSelected(account.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? accountColor.withValues(alpha: 0.3)
                            : DesignTokens.surfaceDark,
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
                    border: Border.all(
                      color: isSelected ? accountColor : Colors.grey[700]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getAccountIcon(type),
                        size: 18,
                        color:
                            isSelected
                                ? DesignTokens.primaryColor
                                : Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          color:
                              isSelected
                                  ? DesignTokens.primaryColor
                                  : Colors.grey[500],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}
