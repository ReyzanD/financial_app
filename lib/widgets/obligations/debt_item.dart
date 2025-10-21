import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/utils/formatters.dart';

class DebtItem extends StatelessWidget {
  final FinancialObligation debt;

  const DebtItem({super.key, required this.debt});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Iconsax.card, color: Colors.red),
        ),
        title: Text(debt.name, style: TextStyle(color: Colors.white)),
        subtitle: Text(
          'Sisa: ${CurrencyFormatter.formatRupiah(debt.currentBalance?.toInt() ?? 0)}',
          style: TextStyle(color: Colors.grey),
        ),
        trailing: Text(
          CurrencyFormatter.formatRupiah(debt.monthlyAmount.toInt()),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
