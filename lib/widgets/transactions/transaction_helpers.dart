import 'package:flutter/material.dart';
import 'package:financial_app/utils/design_tokens.dart';

Color getCategoryColor(String category) {
  switch (category) {
    case 'Gaji':
      return DesignTokens.chartGreen;
    case 'Investasi':
      return DesignTokens.chartDarkGreen;
    case 'Freelance':
      return DesignTokens.chartTeal;
    case 'Makanan & Minuman':
      return DesignTokens.chartRed;
    case 'Transportasi':
      return DesignTokens.chartOrange;
    case 'Belanja':
      return DesignTokens.chartPurple;
    case 'Hiburan':
      return DesignTokens.chartDarkBlueGrey;
    case 'Kesehatan':
      return DesignTokens.chartDarkOrange;
    case 'Pendidikan':
      return DesignTokens.chartBlue;
    case 'Tabungan':
      return DesignTokens.chartDarkTeal;
    case 'Tagihan & Utilitas':
      return DesignTokens.chartGrey;
    default:
      return Colors.grey;
  }
}

IconData getCategoryIcon(String category) {
  switch (category) {
    case 'Gaji':
      return Icons.account_balance_wallet_rounded;
    case 'Freelance':
      return Icons.work_outline_rounded;
    case 'Investasi':
      return Icons.trending_up_rounded;
    case 'Makanan & Minuman':
      return Icons.restaurant_rounded;
    case 'Belanja':
      return Icons.shopping_bag_rounded;
    case 'Transportasi':
      return Icons.directions_car_rounded;
    case 'Tagihan & Utilitas':
    case 'Tagihan':
      return Icons.receipt_long_rounded;
    case 'Hiburan':
      return Icons.sports_esports_rounded;
    case 'Kesehatan':
      return Icons.local_hospital_rounded;
    case 'Pendidikan':
      return Icons.school_rounded;
    case 'Tabungan':
      return Icons.savings_rounded;
    default:
      return Icons.category_rounded;
  }
}

String formatDate(String dateStr) {
  try {
    final date = DateTime.parse(dateStr);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      // Show time only for today's transactions
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  } catch (_) {
    return dateStr;
  }
}
