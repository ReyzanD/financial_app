import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/widgets/transactions/transaction_helpers.dart';
import 'package:financial_app/widgets/transactions/transaction_detail_screen.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/logger_service.dart';

class TransactionCard extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback? onDeleted;

  const TransactionCard({super.key, required this.transaction, this.onDeleted});

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    // Immediately hide if dismissed
    if (_isDismissed) {
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
    final categoryColor =
        widget.transaction['category_color'] != null
            ? Color(
              int.parse(
                    widget.transaction['category_color'].substring(1, 7),
                    radix: 16,
                  ) +
                  0xFF000000,
            )
            : Colors.grey;
    final date = widget.transaction['date'] as String? ?? '';
    final location = widget.transaction['location'] as String? ?? '';

    return Dismissible(
      key: Key(widget.transaction['id']?.toString() ?? ''),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: Text(
                'Hapus Transaksi?',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              content: Text(
                'Apakah Anda yakin ingin menghapus transaksi ini? Saldo akan dikembalikan.',
                style: GoogleFonts.poppins(color: Colors.grey[400]),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Hapus',
                    style: GoogleFonts.poppins(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        // Immediately hide the widget
        setState(() {
          _isDismissed = true;
        });

        // Perform API call to delete from server
        final apiService = ApiService();
        final transactionId = widget.transaction['id']?.toString() ?? '';

        print(' [TransactionCard] Starting deletion for ID: $transactionId');

        try {
          final result = await apiService.deleteTransaction(transactionId);
          LoggerService.success('Transaction deleted successfully');

          // Only refresh parent data after successful deletion
          LoggerService.debug('Calling onDeleted callback to refresh data');
          widget.onDeleted?.call();
          LoggerService.debug('onDeleted callback executed successfully');

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Transaksi berhasil dihapus',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          print(' [TransactionCard] Deletion failed: $e');
          // If deletion fails, show the widget again
          if (mounted) {
            setState(() {
              _isDismissed = false;
            });
          }

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Gagal menghapus transaksi: $e',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => TransactionDetailScreen(
                    transaction: widget.transaction,
                    onDeleted: widget.onDeleted,
                  ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isIncome
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Category Icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: categoryColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  getCategoryIcon(category),
                  color: categoryColor,
                  size: 26,
                ),
              ),

              const SizedBox(width: 12),

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
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$category • $location',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDate(date),
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 10,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isIncome
                              ? Colors.green.withOpacity(0.15)
                              : Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isIncome
                                ? Colors.green.withOpacity(0.4)
                                : Colors.red.withOpacity(0.4),
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
    );
  }
}
