import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/Screen/financial_obligations_screen.dart';
import 'package:financial_app/Screen/transaction_history_screen.dart';
import 'package:financial_app/Screen/recurring_transactions_screen.dart';
import 'package:financial_app/Screen/backup_screen.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        'icon': Iconsax.note_2,
        'label': 'Riwayat',
        'color': const Color(0xFF8B5FBF),
        'onTap':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TransactionHistoryScreen(),
              ),
            ),
      },
      {
        'icon': Iconsax.receipt_2,
        'label': 'Tagihan',
        'color': const Color(0xFFE91E63),
        'onTap':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FinancialObligationsScreen(),
              ),
            ),
      },
      {
        'icon': Iconsax.shield_tick,
        'label': 'Backup',
        'color': const Color(0xFF4CAF50),
        'onTap':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BackupScreen()),
            ),
      },
      {
        'icon': Iconsax.repeat,
        'label': 'Berulang',
        'color': const Color(0xFF2196F3),
        'onTap':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RecurringTransactionsScreen(),
              ),
            ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More Actions',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildQuickActionItem(
              context: context,
              icon: action['icon'] as IconData,
              label: action['label'] as String,
              color: action['color'] as Color,
              onTap: action['onTap'] as VoidCallback,
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
