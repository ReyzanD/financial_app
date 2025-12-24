import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/services/obligation_service.dart';
import 'package:financial_app/services/payment_history_service.dart';
import 'package:financial_app/l10n/app_localizations.dart';

class ObligationItem extends StatelessWidget {
  final FinancialObligation obligation;
  final VoidCallback onTap;
  final VoidCallback? onPaymentRecorded;

  const ObligationItem({
    super.key,
    required this.obligation,
    required this.onTap,
    this.onPaymentRecorded,
  });

  @override
  Widget build(BuildContext context) {
    final isDebt = obligation.type == ObligationType.debt;
    final daysUntilDue = obligation.daysUntilDue;
    final urgencyColor = _getUrgencyColor(daysUntilDue);
    final isOverdue = daysUntilDue < 0;
    final isDueSoon = daysUntilDue >= 0 && daysUntilDue <= 3;

    return Dismissible(
      key: Key(obligation.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)!.mark_as_paid,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade400, Colors.red.shade600],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              AppLocalizations.of(context)!.delete,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          // Mark as paid
          _showPaymentDialog(context);
        } else if (direction == DismissDirection.endToStart) {
          // Delete - handled in details modal
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Show delete confirmation
          return await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1A1A1A),
                      title: Text(
                        '${AppLocalizations.of(context)!.delete_bill_confirm} "${obligation.name}"?',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      content: Text(
                        '${AppLocalizations.of(context)!.delete_bill_confirm} "${obligation.name}"?',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: Text(AppLocalizations.of(context)!.delete),
                        ),
                      ],
                    ),
              ) ??
              false;
        }
        return true;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: urgencyColor.withOpacity(
              isOverdue || isDueSoon ? 0.4 : 0.15,
            ),
            width: isOverdue || isDueSoon ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: urgencyColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            ListTile(
              leading: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getObligationColor(obligation).withOpacity(0.3),
                      _getObligationColor(obligation).withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _getObligationColor(obligation).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _getObligationIcon(obligation),
                  color: _getObligationColor(obligation),
                  size: 26,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      obligation.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.shade400.withOpacity(0.2),
                            Colors.red.shade600.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.warning_2,
                            size: 12,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.overdue,
                            style: GoogleFonts.poppins(
                              color: Colors.red.shade300,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isDueSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade400.withOpacity(0.2),
                            Colors.orange.shade600.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.clock,
                            size: 12,
                            color: Colors.orange.shade300,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.due_soon,
                            style: GoogleFonts.poppins(
                              color: Colors.orange.shade300,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Iconsax.calendar, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'Jatuh tempo: ${obligation.formattedDueDate}',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (isDebt && obligation.currentBalance != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Iconsax.wallet_3,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Sisa: ${CurrencyFormatter.formatRupiah(obligation.currentBalance!.toInt())}',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Debt progress indicator
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value:
                            obligation.originalAmount != null &&
                                    obligation.originalAmount! > 0
                                ? (obligation.originalAmount! -
                                        obligation.currentBalance!) /
                                    obligation.originalAmount!
                                : 0.0,
                        backgroundColor: Colors.grey[800],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getObligationColor(obligation),
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                  if (obligation.isSubscription) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Iconsax.crown, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${AppLocalizations.of(context)!.subscription} • ${_getSubscriptionCycleName(context, obligation.subscriptionCycle ?? 'monthly')}',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatRupiah(
                      obligation.monthlyAmount.toInt(),
                    ),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          urgencyColor.withOpacity(0.15),
                          urgencyColor.withOpacity(0.25),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: urgencyColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isOverdue
                          ? '${daysUntilDue.abs()} ${AppLocalizations.of(context)!.days_late}'
                          : isDueSoon
                          ? '${daysUntilDue} ${AppLocalizations.of(context)!.days_left}'
                          : '${obligation.dueDate.day} ${AppLocalizations.of(context)!.every_month}',
                      style: GoogleFonts.poppins(
                        color: urgencyColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              onTap: onTap,
            ),
            // Quick Actions Row
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[900]!.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      onPressed: () => _showPaymentDialog(context),
                      icon: Iconsax.tick_circle,
                      label: AppLocalizations.of(context)!.pay,
                      color: Colors.green,
                      isPrimary: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      onPressed: onTap,
                      icon: Iconsax.eye,
                      label: AppLocalizations.of(context)!.details,
                      color: const Color(0xFF8B5FBF),
                      isPrimary: false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required bool isPrimary,
  }) {
    // Helper to get gradient colors
    List<Color> getGradientColors(Color baseColor) {
      if (baseColor == Colors.green) {
        return [Colors.green.shade400, Colors.green.shade600];
      } else if (baseColor == const Color(0xFF8B5FBF)) {
        return [const Color(0xFF8B5FBF), const Color(0xFF6B4C93)];
      } else {
        // For other colors, create lighter/darker variants
        return [
          Color.lerp(baseColor, Colors.white, 0.3) ?? baseColor,
          Color.lerp(baseColor, Colors.black, 0.2) ?? baseColor,
        ];
      }
    }

    if (isPrimary) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: getGradientColors(color),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Color _getUrgencyColor(int daysUntilDue) {
    if (daysUntilDue < 0) {
      return Colors.red.shade400; // Overdue
    } else if (daysUntilDue <= 3) {
      return Colors.orange.shade400; // Due soon
    } else if (daysUntilDue <= 7) {
      return Colors.blue.shade400; // Upcoming
    } else {
      return Colors.grey.shade400; // Normal
    }
  }

  Color _getObligationColor(FinancialObligation obligation) {
    switch (obligation.type) {
      case ObligationType.bill:
        return Colors.blue.shade400;
      case ObligationType.debt:
        return Colors.red.shade400;
      case ObligationType.subscription:
        return const Color(0xFFEC4899); // Pink-500 equivalent
    }
  }

  IconData _getObligationIcon(FinancialObligation obligation) {
    switch (obligation.type) {
      case ObligationType.bill:
        return Icons.receipt;
      case ObligationType.debt:
        return Icons.credit_card;
      case ObligationType.subscription:
        return Icons.subscriptions;
    }
  }

  void _showPaymentDialog(BuildContext context) {
    final amountController = TextEditingController(
      text: obligation.monthlyAmount.toInt().toString(),
    );
    final dateController = TextEditingController(
      text: DateTime.now().toString().split(' ')[0],
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              AppLocalizations.of(context)!.record_payment,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  obligation.name,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.payment_amount,
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF8B5FBF)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dateController,
                  readOnly: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.payment_date,
                    labelStyle: const TextStyle(color: Colors.grey),
                    suffixIcon: const Icon(
                      Icons.calendar_today,
                      color: Colors.grey,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF8B5FBF)),
                    ),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      dateController.text = date.toString().split(' ')[0];
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  AppLocalizations.of(context)!.cancel,
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.invalid_amount,
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    final paymentData = {
                      'amount_paid': amount,
                      'payment_date': dateController.text,
                      'payment_method': 'manual',
                    };

                    // Record payment using payment history service
                    final paymentService = PaymentHistoryService();
                    await paymentService.recordPayment(
                      obligation.id,
                      paymentData,
                    );

                    // Also record in API
                    await ObligationService().recordPayment(
                      obligation.id,
                      paymentData,
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.payment_recorded,
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                      onPaymentRecorded?.call();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${AppLocalizations.of(context)!.payment_failed}: $e',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5FBF),
                ),
                child: Text(
                  AppLocalizations.of(context)!.save,
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  String _getSubscriptionCycleName(BuildContext context, String cycle) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return cycle;

    switch (cycle) {
      case 'monthly':
        return l10n.subscription_cycle_monthly;
      case 'yearly':
        return l10n.subscription_cycle_yearly;
      case 'weekly':
        return l10n.subscription_cycle_weekly;
      default:
        return cycle;
    }
  }
}
