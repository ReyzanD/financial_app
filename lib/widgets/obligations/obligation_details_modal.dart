import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/obligation_service.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/widgets/obligations/add_obligation_modal.dart';
import 'package:financial_app/widgets/obligations/reminder_settings.dart';
import 'package:financial_app/l10n/app_localizations.dart';

class ObligationDetailsModal extends StatefulWidget {
  final FinancialObligation obligation;

  const ObligationDetailsModal({super.key, required this.obligation});

  @override
  State<ObligationDetailsModal> createState() => _ObligationDetailsModalState();
}

class _ObligationDetailsModalState extends State<ObligationDetailsModal> {
  final ObligationService _obligationService = ObligationService();
  bool _isDeleting = false;

  Future<void> _deleteObligation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(
              AppLocalizations.of(context)!.delete_obligation,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: Text(
              '${AppLocalizations.of(context)!.delete_obligation_confirm} "${widget.obligation.name}"?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(AppLocalizations.of(context)!.delete),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _obligationService.deleteObligation(widget.obligation.id);

      if (!mounted) return;

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.obligation_deleted_successfully,
          ),
          backgroundColor: Color(0xFF8B5FBF),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.error}: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editObligation() async {
    // Convert obligation to map format for editing
    final obligationData = {
      'obligation_id_232143': widget.obligation.id,
      'name_232143': widget.obligation.name,
      'type_232143': widget.obligation.type.name,
      'category_232143': widget.obligation.category,
      'monthly_amount_232143': widget.obligation.monthlyAmount,
      'dueDate_232143': widget.obligation.dueDate.day,
      'original_amount_232143': widget.obligation.originalAmount,
      'current_balance_232143': widget.obligation.currentBalance,
      'interest_rate_232143': widget.obligation.interestRate,
      'subscription_cycle_232143': widget.obligation.subscriptionCycle,
      'minimum_payment_232143': widget.obligation.minimumPayment,
      'payoff_strategy_232143': widget.obligation.payoffStrategy,
    };

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D0D0D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => AddObligationModal(initialObligation: obligationData),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Color _getObligationColor() {
    switch (widget.obligation.type) {
      case ObligationType.bill:
        return Colors.blue;
      case ObligationType.debt:
        return Colors.red;
      case ObligationType.subscription:
        return Colors.green;
    }
  }

  IconData _getObligationIcon() {
    switch (widget.obligation.type) {
      case ObligationType.bill:
        return Iconsax.receipt;
      case ObligationType.debt:
        return Iconsax.card;
      case ObligationType.subscription:
        return Iconsax.crown;
    }
  }

  String _getTypeName() {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return '';
    switch (widget.obligation.type) {
      case ObligationType.bill:
        return l10n.bill;
      case ObligationType.debt:
        return l10n.debt;
      case ObligationType.subscription:
        return l10n.subscription;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getObligationColor();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getObligationIcon(), color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.obligation.name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getTypeName(),
                        style: TextStyle(color: color, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Monthly Amount Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1F1F1F), const Color(0xFF1A1A1A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Iconsax.wallet_2, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.monthly_amount,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.formatRupiah(
                            widget.obligation.monthlyAmount,
                          ),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Details Grid
            _buildDetailRow(
              AppLocalizations.of(context)!.due_date,
              '${AppLocalizations.of(context)!.date_label} ${widget.obligation.dueDate.day}',
            ),
            if (widget.obligation.daysUntilDue >= 0)
              _buildDetailRow(
                AppLocalizations.of(context)!.days_remaining,
                '${widget.obligation.daysUntilDue} ${AppLocalizations.of(context)!.days}',
              ),
            if (widget.obligation.category != null)
              _buildDetailRow(
                AppLocalizations.of(context)!.category,
                _getCategoryName(widget.obligation.category!),
              ),

            // Debt specific details
            if (widget.obligation.type == ObligationType.debt) ...[
              if (widget.obligation.currentBalance != null)
                _buildDetailRow(
                  AppLocalizations.of(context)!.current_balance,
                  CurrencyFormatter.formatRupiah(
                    widget.obligation.currentBalance!,
                  ),
                ),
              if (widget.obligation.originalAmount != null)
                _buildDetailRow(
                  AppLocalizations.of(context)!.original_amount,
                  CurrencyFormatter.formatRupiah(
                    widget.obligation.originalAmount!,
                  ),
                ),
              if (widget.obligation.interestRate != null)
                _buildDetailRow(
                  AppLocalizations.of(context)!.interest,
                  '${widget.obligation.interestRate!.toStringAsFixed(2)}%',
                ),
              if (widget.obligation.minimumPayment != null)
                _buildDetailRow(
                  AppLocalizations.of(context)!.minimum_payment,
                  CurrencyFormatter.formatRupiah(
                    widget.obligation.minimumPayment!,
                  ),
                ),
            ],

            // Subscription specific details
            if (widget.obligation.type == ObligationType.subscription) ...[
              if (widget.obligation.subscriptionCycle != null)
                _buildDetailRow(
                  AppLocalizations.of(context)!.cycle,
                  _getSubscriptionCycleName(
                    widget.obligation.subscriptionCycle!,
                  ),
                ),
            ],

            const SizedBox(height: 24),

            // Reminder Settings
            ReminderSettings(obligation: widget.obligation),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isDeleting ? null : _deleteObligation,
                    icon:
                        _isDeleting
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.red,
                              ),
                            )
                            : const Icon(Iconsax.trash, size: 18),
                    label: Text(AppLocalizations.of(context)!.delete),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isDeleting ? null : _editObligation,
                    icon: const Icon(Iconsax.edit, size: 18),
                    label: Text(AppLocalizations.of(context)!.edit),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5FBF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String category) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return category;

    switch (category) {
      case 'utilities':
        return l10n.utilities;
      case 'housing':
        return l10n.housing;
      case 'transportation':
        return l10n.transportation;
      case 'entertainment':
        return l10n.entertainment;
      case 'other':
        return l10n.other;
      default:
        return category;
    }
  }

  String _getSubscriptionCycleName(String cycle) {
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
