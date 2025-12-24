import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/state/app_state.dart';
import 'package:financial_app/models/transaction_model.dart';
import 'package:financial_app/Screen/transaction_screen.dart';
import 'package:financial_app/utils/responsive_helper.dart';

class RecentTransactions extends StatelessWidget {
  const RecentTransactions({super.key});

  Widget _buildTransactionItem(TransactionModel transaction, BuildContext context) {
    final isIncome = transaction.type == 'income';

    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveHelper.verticalSpacing(context, 8),
      ),
      padding: ResponsiveHelper.padding(context, multiplier: 0.75),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.borderRadius(context, 12),
        ),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Container(
            width: ResponsiveHelper.iconSize(context, 40),
            height: ResponsiveHelper.iconSize(context, 40),
            decoration: BoxDecoration(
              color: Color(
                int.parse(transaction.categoryColor.replaceAll('#', '0xFF')),
              ).withOpacity(0.2),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.borderRadius(context, 10),
              ),
            ),
            child: Icon(
              isIncome ? Iconsax.arrow_down : Iconsax.arrow_up,
              color: Color(
                int.parse(transaction.categoryColor.replaceAll('#', '0xFF')),
              ),
              size: ResponsiveHelper.iconSize(context, 20),
            ),
          ),
          SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.fontSize(context, 14),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  transaction.categoryName,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: ResponsiveHelper.fontSize(context, 12),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatRupiah(
                  transaction.amount.toInt().abs(),
                ),
                style: GoogleFonts.poppins(
                  color: isIncome ? Colors.green : Colors.white,
                  fontSize: ResponsiveHelper.fontSize(context, 14),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${transaction.transactionDate.hour.toString().padLeft(2, '0')}:${transaction.transactionDate.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: ResponsiveHelper.fontSize(context, 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final recentTransactions = appState.transactions.take(4).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: ResponsiveHelper.horizontalPadding(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: ResponsiveHelper.fontSize(context, 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TransactionsScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'View All',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF8B5FBF),
                        fontSize: ResponsiveHelper.fontSize(context, 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
            if (appState.isLoading)
              Padding(
                padding: ResponsiveHelper.padding(context, multiplier: 2.0),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF8B5FBF),
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (recentTransactions.isEmpty)
              Padding(
                padding: ResponsiveHelper.horizontalPadding(context),
                child: Container(
                  padding: ResponsiveHelper.padding(context, multiplier: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.borderRadius(context, 12),
                    ),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        color: Colors.grey[600],
                        size: ResponsiveHelper.iconSize(context, 48),
                      ),
                      SizedBox(
                        height: ResponsiveHelper.verticalSpacing(context, 12),
                      ),
                      Text(
                        'No transactions yet',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: ResponsiveHelper.fontSize(context, 14),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveHelper.verticalSpacing(context, 4),
                      ),
                      Text(
                        'Start by adding your first transaction',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: ResponsiveHelper.fontSize(context, 11),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: ResponsiveHelper.horizontalPadding(context),
                child: Column(
                  children:
                      recentTransactions
                          .map(
                            (transaction) => _buildTransactionItem(transaction, context),
                          )
                          .toList(),
                ),
              ),
          ],
        );
      },
    );
  }
}
