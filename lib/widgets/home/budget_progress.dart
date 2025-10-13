import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/utils/formatters.dart';

class BudgetProgress extends StatelessWidget {
  const BudgetProgress({super.key});

  @override
  Widget build(BuildContext context) {
    final budgets = [
      {
        'category': 'Makanan',
        'used': 0,
        'total': 1000000,
        'color': Color(0xFFE74C3C),
      },
      {
        'category': 'Transportasi',
        'used': 300000,
        'total': 500000,
        'color': Color(0xFFF39C12),
      },
      {
        'category': 'Hiburan',
        'used': 200000,
        'total': 300000,
        'color': Color(0xFF9B59B6),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget Progress',
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
        ...budgets.map(
          (budget) => _buildBudgetItem(
            category: budget['category'] as String,
            used: budget['used'] as int,
            total: budget['total'] as int,
            color: budget['color'] as Color,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetItem({
    required String category,
    required int used,
    required int total,
    required Color color,
  }) {
    final percentage = (used / total).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${CurrencyFormatter.formatRupiah(used)} / '
                '${CurrencyFormatter.formatRupiah(total)}',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[800],
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(percentage * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
