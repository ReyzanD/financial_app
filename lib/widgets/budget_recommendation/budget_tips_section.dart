import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// Widget untuk menampilkan tips mengelola budget
class BudgetTipsSection extends StatelessWidget {
  const BudgetTipsSection({super.key});

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              const Icon(Iconsax.lamp, color: Color(0xFFFFB74D), size: 20),
              const SizedBox(width: 8),
              Text(
                'Tips Mengelola Budget',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem(
            '1. Prioritaskan dana darurat minimal 6 bulan pengeluaran',
          ),
          _buildTipItem(
            '2. Sisihkan tabungan dan investasi di awal bulan (pay yourself first)',
          ),
          _buildTipItem(
            '3. Tinjau dan sesuaikan budget setiap bulan sesuai kebutuhan',
          ),
          _buildTipItem(
            '4. Gunakan metode amplop untuk kategori yang sering over budget',
          ),
          _buildTipItem(
            '5. Batasi pengeluaran impulsif dengan aturan tunggu 24 jam',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Iconsax.tick_circle, color: Color(0xFF4CAF50), size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

