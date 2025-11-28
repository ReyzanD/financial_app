import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/widgets/obligations/add_obligation_modal.dart';
import 'package:financial_app/widgets/obligations/obligation_details_modal.dart';

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

  static Future<bool?> showAddObligationModal(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D0D0D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AddObligationModal(),
    );

    return result;
  }

  static Future<void> showObligationDetails(
    BuildContext context,
    FinancialObligation obligation,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D0D0D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ObligationDetailsModal(obligation: obligation),
    );
  }
}
