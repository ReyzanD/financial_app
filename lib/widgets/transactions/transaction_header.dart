import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../state/app_state.dart';

class TransactionHeader extends StatelessWidget {
  const TransactionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          double totalBalance = 0;
          if (!appState.isLoading && appState.error == null) {
            for (var transaction in appState.transactions) {
              if (transaction.type == 'income') {
                totalBalance += transaction.amount;
              } else {
                totalBalance -= transaction.amount;
              }
            }
          }

          final numberFormat = NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp',
            decimalDigits: 0,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaksi',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!appState.isLoading && appState.error == null)
                    Text(
                      numberFormat.format(totalBalance),
                      style: GoogleFonts.poppins(
                        color: totalBalance >= 0 ? Colors.green : Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Kelola semua transaksi keuangan Anda',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
