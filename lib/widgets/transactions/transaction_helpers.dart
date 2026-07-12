import 'package:flutter/material.dart';

Color getCategoryColor(String category) {
  switch (category) {
    case 'Gaji':
      return const Color(0xFF2ecc71);
    case 'Investasi':
      return const Color(0xFF27ae60);
    case 'Freelance':
      return const Color(0xFF1abc9c);
    case 'Makanan & Minuman':
      return const Color(0xFFe74c3c);
    case 'Transportasi':
      return const Color(0xFFf39c12);
    case 'Belanja':
      return const Color(0xFF9b59b6);
    case 'Hiburan':
      return const Color(0xFF34495e);
    case 'Kesehatan':
      return const Color(0xFFe67e22);
    case 'Pendidikan':
      return const Color(0xFF2980b9);
    case 'Tabungan':
      return const Color(0xFF16a085);
    case 'Tagihan & Utilitas':
      return const Color(0xFF95a5a6);
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
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
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
