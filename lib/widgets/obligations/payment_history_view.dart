import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/payment_history_service.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Widget untuk menampilkan payment history untuk obligation
class PaymentHistoryView extends StatefulWidget {
  final String obligationId;
  final String obligationName;

  const PaymentHistoryView({
    super.key,
    required this.obligationId,
    required this.obligationName,
  });

  @override
  State<PaymentHistoryView> createState() => _PaymentHistoryViewState();
}

class _PaymentHistoryViewState extends State<PaymentHistoryView> {
  final PaymentHistoryService _paymentService = PaymentHistoryService();
  List<Map<String, dynamic>> _payments = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() => _isLoading = true);
    try {
      final payments = await _paymentService.getPaymentHistory(
        widget.obligationId,
      );
      final stats = await _paymentService.getPaymentStatistics(
        widget.obligationId,
      );

      setState(() {
        _payments = payments;
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      LoggerService.error('Error loading payment history', error: e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _delete_payment(String paymentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(
              AppLocalizations.of(context)!.delete_payment,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: Text(
              AppLocalizations.of(context)!.delete_payment_confirm,
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

    if (confirmed == true) {
      try {
        await _paymentService.deletePayment(widget.obligationId, paymentId);
        await _loadPaymentHistory();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.payment_deleted,
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.payment_delete_failed,
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Statistics Card
        if (_statistics['total_payments'] as int > 0) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF8B5FBF).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.payment_statistics,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        AppLocalizations.of(context)!.total_payments,
                        '${_statistics['total_payments']}',
                        Iconsax.wallet_3,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        AppLocalizations.of(context)!.total_amount,
                        CurrencyFormatter.formatRupiah(
                          (_statistics['total_amount'] as num?)?.toDouble() ??
                              0.0,
                        ),
                        Iconsax.money_recive,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        AppLocalizations.of(context)!.on_time_payments,
                        '${_statistics['on_time_payments']}',
                        Iconsax.tick_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        AppLocalizations.of(context)!.late_payments,
                        '${_statistics['late_payments']}',
                        Iconsax.warning_2,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        // Payment History List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.payment_history,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_payments.length} pembayaran',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (_payments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Iconsax.receipt, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.no_payment_history,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.payment_history_hint,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _payments.length,
              itemBuilder: (context, index) {
                final payment = _payments[index];
                return _buildPaymentItem(payment);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(Map<String, dynamic> payment) {
    final amount = (payment['amount_paid'] as num?)?.toDouble() ?? 0.0;
    final paymentDateStr =
        payment['payment_date']?.toString() ??
        payment['recorded_at']?.toString();
    DateTime? paymentDate;

    if (paymentDateStr != null) {
      try {
        paymentDate = DateTime.parse(paymentDateStr);
      } catch (e) {
        LoggerService.warning('Error parsing payment date', error: e);
      }
    }

    final wasOnTime = payment['was_on_time'] as bool? ?? true;
    final paymentMethod = payment['payment_method']?.toString() ?? 'manual';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              wasOnTime
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
                  wasOnTime
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              wasOnTime ? Iconsax.tick_circle : Iconsax.warning_2,
              color: wasOnTime ? Colors.green : Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyFormatter.formatRupiah(amount.toInt()),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Iconsax.calendar, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      paymentDate != null
                          ? DateFormat(
                            'dd MMM yyyy',
                            'id_ID',
                          ).format(paymentDate)
                          : AppLocalizations.of(context)!.unknown_date,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            wasOnTime
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        wasOnTime
                            ? AppLocalizations.of(context)!.on_time
                            : AppLocalizations.of(context)!.late,
                        style: GoogleFonts.poppins(
                          color: wasOnTime ? Colors.green : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (paymentMethod != 'manual') ...[
                  const SizedBox(height: 4),
                  Text(
                    'Metode: ${_getPaymentMethodName(paymentMethod)}',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.trash, color: Colors.red, size: 20),
            onPressed: () => _delete_payment(payment['id']?.toString() ?? ''),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName(String method) {
    const methodMap = {
      'cash': 'Tunai',
      'bank_transfer': 'Transfer Bank',
      'credit_card': 'Kartu Kredit',
      'debit_card': 'Kartu Debit',
      'e_wallet': 'E-Wallet',
      'auto_pay': 'Auto Pay',
      'manual': 'Manual',
    };
    return methodMap[method] ?? method;
  }
}
