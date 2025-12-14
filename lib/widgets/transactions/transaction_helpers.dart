import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

Color getCategoryColor(String category) {
  // For backwards compatibility and default value
  return Colors.grey;
}

IconData getCategoryIcon(String category) {
  switch (category) {
    case 'Gaji':
      return Icons.account_balance_wallet_rounded;
    case 'Freelance':
      return Icons.work_outline_rounded;
    case 'Belanja':
      return Icons.shopping_bag_rounded;
    case 'Transportasi':
      return Icons.directions_car_rounded;
    case 'Tagihan':
      return Icons.receipt_long_rounded;
    case 'Hiburan':
      return Icons.sports_esports_rounded;
    default:
      return Icons.category_rounded;
  }
}

String formatDate(String date) {
  // Simple date formatting
  return date;
}
