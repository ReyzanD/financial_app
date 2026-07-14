import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/widgets/transactions/transaction_helpers.dart';
import 'package:financial_app/widgets/transactions/transaction_detail_screen.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/utils/biometric_helper.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/features/transactions/presentation/controllers/transaction_controller.dart';

class TransactionCard extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback? onDeleted;
  final VoidCallback? onUpdated;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onDeleted,
    this.onUpdated,
  });

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard> {
  bool _isDeleting = false; // Track if deletion is in progress

  @override
  Widget build(BuildContext context) {
    // If deletion is in progress, hide the widget immediately
    if (_isDeleting) {
      return const SizedBox.shrink();
    }
    // Log transaction data for debugging
    LoggerService.debug(
      'TransactionCard Data',
      error: {
        'type': widget.transaction['type'],
        'amount': widget.transaction['amount'],
        'category': widget.transaction['category'],
        'category_color': widget.transaction['category_color'],
      },
    );

    final isIncome = widget.transaction['type'] == 'income';
    final amount =
        double.tryParse(widget.transaction['amount']?.toString() ?? '0') ?? 0.0;
    final category =
        widget.transaction['category'] as String? ?? 'Uncategorized';
    Color categoryColor = Colors.grey;
    if (widget.transaction['category_color'] != null) {
      final hex = widget.transaction['category_color'].toString();
      try {
        // Handle formats: #RRGGBB, #RGB, RRGGBB, or just a color name
        final cleanHex = hex.startsWith('#') ? hex.substring(1) : hex;
        if (cleanHex.length >= 6) {
          categoryColor = Color(
            int.parse(cleanHex.substring(0, 6), radix: 16) + 0xFF000000,
          );
        }
      } catch (_) {
        categoryColor = Colors.grey;
      }
    }
    final date = widget.transaction['date'] as String? ?? '';
    final location = widget.transaction['location'] as String? ?? '';
    final accountName = widget.transaction['account_name'] as String?;

    return Dismissible(
      key: Key(widget.transaction['id']?.toString() ?? ''),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            final l10n = AppLocalizations.of(context);
            return AlertDialog(
              backgroundColor: DesignTokens.surfaceDark,
              title: Text(
                l10n?.delete_transaction_confirm ?? 'Hapus Transaksi?',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              content: Text(
                l10n?.delete_transaction_message_balance ??
                    'Apakah Anda yakin ingin menghapus transaksi ini? Saldo akan dikembalikan.',
                style: GoogleFonts.poppins(color: Colors.grey[400]),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    l10n?.cancel ?? 'Batal',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    l10n?.delete ?? 'Hapus',
                    style: GoogleFonts.poppins(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        // onDismissed is called AFTER the widget is dismissed
        // Immediately mark as deleting to hide the widget
        setState(() {
          _isDeleting = true;
        });

        final transactionId = widget.transaction['id']?.toString() ?? '';
        LoggerService.debug(
          '[TransactionCard] Dismissed, starting deletion for ID: $transactionId',
        );

        // Perform async deletion - onDeleted will be called after successful deletion
        _performDeletion(transactionId);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      child: Semantics(
        label: '${widget.transaction['description'] ?? widget.transaction['category'] ?? 'Transaksi'}, ${CurrencyFormatter.formatRupiah(amount.abs())}',
        hint: 'Ketuk untuk detail',
        button: true,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => TransactionDetailScreen(
                      transaction: widget.transaction,
                      onDeleted: widget.onDeleted,
                      onUpdated: widget.onUpdated,
                    ),
              ),
            );
          },
          child: Container(
          margin: EdgeInsets.only(
            bottom: ResponsiveHelper.verticalSpacing(context, 12),
          ),
          padding: ResponsiveHelper.padding(context),
          decoration: BoxDecoration(
            color: DesignTokens.surfaceDark,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.borderRadius(context, 16),
            ),
            border: Border.all(
              color:
                  isIncome
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Category Icon
              Container(
                width: ResponsiveHelper.iconSize(context, 52),
                height: ResponsiveHelper.iconSize(context, 52),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.borderRadius(context, 14),
                  ),
                  border: Border.all(
                    color: categoryColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  getCategoryIcon(category),
                  color: categoryColor,
                  size: ResponsiveHelper.iconSize(context, 26),
                ),
              ),

              SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 12)),

              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.transaction['description'] as String? ??
                          'No description',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: ResponsiveHelper.fontSize(context, 16),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.verticalSpacing(context, 4),
                    ),
                    Text(
                      [
                        category,
                        if (accountName != null && accountName.isNotEmpty)
                          accountName,
                        if (location.isNotEmpty) location,
                      ].join(' • '),
                      style: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: ResponsiveHelper.fontSize(context, 12),
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.verticalSpacing(context, 4),
                    ),
                    Text(
                      formatDate(date),
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: ResponsiveHelper.fontSize(context, 10),
                      ),
                    ),
                  ],
                ),
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatRupiah(amount.abs()),
                    style: GoogleFonts.poppins(
                      color: isIncome ? Colors.green : Colors.white,
                      fontSize: ResponsiveHelper.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.verticalSpacing(context, 4),
                  ),
                  Container(
                    padding: ResponsiveHelper.symmetricPadding(
                      context,
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isIncome
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isIncome
                                ? Colors.green.withValues(alpha: 0.4)
                                : Colors.red.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isIncome
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          size: 12,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isIncome ? 'MASUK' : 'KELUAR',
                          style: GoogleFonts.poppins(
                            color: isIncome ? Colors.green : Colors.red,
                            fontSize: 10,
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
      ),
      ),
    );
  }

  Future<void> _performDeletion(String transactionId) async {
    // Capture context early for safe use after async gaps
    final currentContext = context;
    final l10n = AppLocalizations.of(context);

    // Exit if widget is already unmounted
    if (!mounted) return;

    // Check if biometric should be required
    final shouldRequire = await BiometricHelper.shouldRequireBiometric();

    if (!context.mounted) return;
    if (shouldRequire) {
      // Biometric is available and enabled - require authentication
      final authenticated = await BiometricHelper.requestBiometricAuth(
        context: currentContext, // Use captured context
        reason:
            l10n?.authentication_required_to_delete ??
            'Autentikasi diperlukan untuk menghapus transaksi',
      );

      if (!authenticated) {
        // User cancelled or authentication failed
        // Restore the widget and refresh to show it again
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
        // Refresh to restore the item in the list
        widget.onDeleted?.call();

        // Check if context is still mounted before showing SnackBar
        if (currentContext.mounted) {
          ErrorHandlerService.showWarningSnackbar(
            currentContext,
            l10n?.authentication_cancelled_delete ?? 'Autentikasi dibatalkan',
          );
        }
        return;
      }
    }
    // If biometric is not available/enabled, proceed with deletion without authentication

    final ctrl = getIt<TransactionController>();

    LoggerService.debug(
      '[TransactionCard] Starting deletion for ID: $transactionId',
    );

    try {
      await ctrl.deleteTransaction(transactionId);
      LoggerService.success('Transaction deleted successfully');

      // Refresh the parent list after successful deletion
      widget.onDeleted?.call();

      if (currentContext.mounted) {
        ErrorHandlerService.showSuccessSnackbar(
          currentContext,
          l10n?.transaction_deleted_successfully ??
              'Transaksi berhasil dihapus',
        );
      }
    } catch (e) {
      LoggerService.error('[TransactionCard] Deletion failed', error: e);

      // Restore the widget if deletion failed
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }

      // Refresh to restore the item in the list
      widget.onDeleted?.call();

      if (currentContext.mounted) {
        ErrorHandlerService.showErrorSnackbar(
          currentContext,
          '${l10n?.failed_to_delete_transaction ?? 'Gagal menghapus transaksi'}: ${ErrorHandlerService.getUserFriendlyMessage(e)}',
        );
      }
    }
  }
}
