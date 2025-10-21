import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/models/financial_obligation.dart';

class ObligationHelpers {
  static Color getObligationColor(FinancialObligation obligation) {
    switch (obligation.type) {
      case ObligationType.bill:
        return Colors.blue;
      case ObligationType.debt:
        return Colors.red;
      case ObligationType.subscription:
        return Colors.green;
    }
  }

  static IconData getObligationIcon(FinancialObligation obligation) {
    switch (obligation.type) {
      case ObligationType.bill:
        return Iconsax.receipt;
      case ObligationType.debt:
        return Iconsax.card;
      case ObligationType.subscription:
        return Iconsax.crown;
    }
  }

  static void showAddObligationModal(BuildContext context) {
    // Stub implementation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tambah kewajiban - fitur akan segera hadir')),
    );
  }

  static void showObligationDetails(
    BuildContext context,
    FinancialObligation obligation,
  ) {
    // Stub implementation
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Detail ${obligation.name}')));
  }
}
