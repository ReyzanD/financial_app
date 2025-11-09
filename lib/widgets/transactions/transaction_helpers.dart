import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

Color getCategoryColor(String category) {
  // For backwards compatibility and default value
  return Colors.grey;
}

IconData getCategoryIcon(String category) {
  switch (category) {
    case 'Gaji':
      return Iconsax.wallet;
    case 'Freelance':
      return Iconsax.code;
    case 'Belanja':
      return Iconsax.shopping_cart;
    case 'Transportasi':
      return Iconsax.car;
    case 'Tagihan':
      return Iconsax.receipt;
    case 'Hiburan':
      return Iconsax.game;
    default:
      return Iconsax.receipt;
  }
}

String formatDate(String date) {
  // Simple date formatting
  return date;
}
