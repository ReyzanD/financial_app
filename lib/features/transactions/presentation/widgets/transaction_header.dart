import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:financial_app/features/transactions/presentation/controllers/transaction_controller.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/utils/design_tokens.dart';

class TransactionHeader extends StatelessWidget {
  const TransactionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      child: Consumer<TransactionController>(
        builder: (context, controller, child) {
          double totalBalance = 0;
          if (!controller.isLoading && controller.error == null) {
            for (var transaction in controller.transactions) {
              if (transaction.type == 'income') {
                totalBalance += transaction.amount;
              } else {
                totalBalance -= transaction.amount;
              }
            }
          }

          final numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      AppLocalizations.of(context)?.transactions ?? 'Transaksi',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (!controller.isLoading && controller.error == null)
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
              const SizedBox(height: DesignTokens.spacing2),
              Text(
                AppLocalizations.of(context)?.manage_all_transactions ?? 'Kelola semua transaksi keuangan Anda',
                style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          );
        },
      ),
    );
  }
}
