import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

Color getCategoryColor(String category) {
  switch (category) {
    case 'Gaji':
      return Colors.green;
    case 'Freelance':
      return Colors.blue;
    case 'Belanja':
      return Colors.orange;
    case 'Transportasi':
      return Colors.yellow;
    case 'Tagihan':
      return Colors.red;
    case 'Hiburan':
      return Colors.purple;
    default:
      return Colors.grey;
  }
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
