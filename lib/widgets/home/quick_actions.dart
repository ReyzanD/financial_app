import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/features/obligations/presentation/screens/financial_obligations_screen.dart';
import 'package:financial_app/features/transactions/presentation/screens/transaction_history_screen.dart';
import 'package:financial_app/features/recurring_transactions/presentation/screens/recurring_transactions_screen.dart';
import 'package:financial_app/features/backup/presentation/screens/backup_screen.dart';
import 'package:financial_app/features/ai_budget_recommendation/presentation/screens/ai_budget_recommendation_screen.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/utils/design_tokens.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        'icon': Iconsax.flash,
        'label': 'AI Budget',
        'color': const Color(0xFFFFB74D),
        'onTap':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AIBudgetRecommendationScreen(),
              ),
            ),
      },
      {
        'icon': Iconsax.note_2,
        'label': 'Riwayat',
        'color': DesignTokens.primaryColor,
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
            fontSize: ResponsiveHelper.fontSize(context, 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveHelper.gridCrossAxisCount(
              context,
              phone: 4,
              tablet: 5,
            ),
            crossAxisSpacing: ResponsiveHelper.horizontalSpacing(context, 10),
            mainAxisSpacing: ResponsiveHelper.verticalSpacing(context, 12),
            childAspectRatio: ResponsiveHelper.isTablet(context) ? 0.9 : 0.85,
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
    final iconSize = ResponsiveHelper.iconSize(context, 48);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.borderRadius(context, 14),
              ),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(
              icon,
              color: color,
              size: ResponsiveHelper.iconSize(context, 22),
            ),
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 6)),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: ResponsiveHelper.fontSize(context, 9),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
