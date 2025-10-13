import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

Color getGoalTypeColor(String type) {
  switch (type) {
    case 'emergency_fund':
      return Colors.green;
    case 'vacation':
      return Colors.blue;
    case 'electronics':
      return Colors.orange;
    case 'vehicle':
      return Colors.yellow;
    case 'house':
      return Colors.purple;
    default:
      return Colors.grey;
  }
}

IconData getGoalTypeIcon(String type) {
  switch (type) {
    case 'emergency_fund':
      return Iconsax.shield_tick;
    case 'vacation':
      return Iconsax.airplane;
    case 'electronics':
      return Iconsax.monitor;
    case 'vehicle':
      return Iconsax.car;
    case 'house':
      return Iconsax.house;
    default:
      return Iconsax.code;
  }
}

String formatDeadline(String deadline) {
  return 'Target: $deadline';
}
