import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/utils/formatters.dart';

class RecentTransactions extends StatelessWidget {
  const RecentTransactions({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = [
      {
        'name': 'Restaurant Sederhana',
        'amount': -75000,
        'category': 'Makanan',
        'time': '19:30',
      },
      {
        'name': 'SPBU Pertamina',
        'amount': -150000,
        'category': 'Transportasi',
        'time': '18:15',
      },
      {
        'name': 'Gaji Bulanan',
        'amount': 12500000,
        'category': 'Gaji',
        'time': '08:00',
      },
      {
        'name': 'Netflix',
        'amount': -49000,
        'category': 'Hiburan',
        'time': '15:20',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transaksi Terbaru',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Lihat Semua',
              style: GoogleFonts.poppins(
                color: Color(0xFF8B5FBF),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...transactions.map(
          (transaction) => _buildTransactionItem(
            name: transaction['name'] as String,
            amount: transaction['amount'] as int,
            category: transaction['category'] as String,
            time: transaction['time'] as String,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem({
    required String name,
    required int amount,
    required String category,
    required String time,
  }) {
    final isIncome = amount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  isIncome
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIncome ? Iconsax.arrow_down : Iconsax.arrow_up,
              color: isIncome ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  category,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatRupiah(amount.abs()),
                style: GoogleFonts.poppins(
                  color: isIncome ? Colors.green : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                time,
                style: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
