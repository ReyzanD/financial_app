import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryBreakdown extends StatelessWidget {
  const CategoryBreakdown({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {
        'name': 'Makanan',
        'amount': 750000,
        'percentage': 35,
        'color': Colors.red,
      },
      {
        'name': 'Transportasi',
        'amount': 500000,
        'percentage': 25,
        'color': Colors.orange,
      },
      {
        'name': 'Belanja',
        'amount': 400000,
        'percentage': 20,
        'color': Colors.blue,
      },
      {
        'name': 'Hiburan',
        'amount': 250000,
        'percentage': 12,
        'color': Colors.purple,
      },
      {
        'name': 'Lainnya',
        'amount': 150000,
        'percentage': 8,
        'color': Colors.grey,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Breakdown Kategori',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...categories.map((category) => _buildCategoryItem(category)),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Color Indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: category['color'] as Color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),

          // Category Name
          Expanded(
            child: Text(
              category['name'] as String,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            ),
          ),

          // Percentage
          Text(
            '${category['percentage']}%',
            style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(width: 12),

          // Amount
          Text(
            'Rp ${category['amount'].toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
