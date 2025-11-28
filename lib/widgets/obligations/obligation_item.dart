import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/services/obligation_service.dart';

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

    return Card(
      color: const Color(0xFF1A1A1A),
      margin: EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getObligationColor(obligation).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getObligationIcon(obligation),
                color: _getObligationColor(obligation),
              ),
            ),
            title: Text(obligation.name, style: TextStyle(color: Colors.white)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jatuh tempo: ${obligation.formattedDueDate}',
                  style: TextStyle(color: Colors.grey),
                ),
                if (isDebt)
                  Text(
                    'Sisa: ${CurrencyFormatter.formatRupiah(obligation.currentBalance?.toInt() ?? 0)}',
                    style: TextStyle(color: Colors.grey),
                  ),
                if (obligation.isSubscription)
                  Text(
                    'Subscription • ${obligation.subscriptionCycle}',
                    style: TextStyle(color: Colors.grey),
                  ),
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  daysUntilDue <= 3
                      ? '$daysUntilDue hari'
                      : '${obligation.dueDate.day} setiap bulan',
                  style: TextStyle(
                    color: daysUntilDue <= 3 ? Colors.red : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            onTap: onTap,
          ),
          // Payment Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ElevatedButton.icon(
              onPressed: () => _showPaymentDialog(context),
              icon: const Icon(Iconsax.tick_circle, size: 18),
              label: Text(
                'Tandai Sudah Bayar',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5FBF),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getObligationColor(FinancialObligation obligation) {
    switch (obligation.type) {
      case ObligationType.bill:
        return Colors.blue;
      case ObligationType.debt:
        return Colors.red;
      case ObligationType.subscription:
        return Colors.pink;
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
              'Catat Pembayaran',
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
                    labelText: 'Jumlah Dibayar (Rp)',
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
                    labelText: 'Tanggal Bayar',
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
                  'Batal',
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
                          'Masukkan jumlah yang valid',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    await ObligationService().recordPayment(obligation.id, {
                      'amount_paid': amount,
                      'payment_date': dateController.text,
                      'payment_method': 'manual',
                    });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Pembayaran berhasil dicatat!',
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
                            'Gagal mencatat pembayaran: $e',
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
                  'Catat',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}
