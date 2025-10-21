import 'package:flutter/material.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/utils/formatters.dart';

class ObligationItem extends StatelessWidget {
  final FinancialObligation obligation;
  final VoidCallback onTap;

  const ObligationItem({
    super.key,
    required this.obligation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDebt = obligation.type == ObligationType.debt;
    final daysUntilDue = obligation.daysUntilDue;

    return Card(
      color: const Color(0xFF1A1A1A),
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getObligationColor(obligation).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getObligationIcon(obligation),
            color: _getObligationColor(obligation),
          ),
        ),
        title: Text(obligation.name, style: TextStyle(color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jatuh tempo: ${obligation.formattedDueDate}',
              style: TextStyle(color: Colors.grey),
            ),
            if (isDebt)
              Text(
                'Sisa: ${CurrencyFormatter.formatRupiah(obligation.currentBalance?.toInt() ?? 0)}',
                style: TextStyle(color: Colors.grey),
              ),
            if (obligation.isSubscription)
              Text(
                'Subscription • ${obligation.subscriptionCycle}',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.formatRupiah(obligation.monthlyAmount.toInt()),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              daysUntilDue <= 3
                  ? '$daysUntilDue hari'
                  : '${obligation.dueDate.day} setiap bulan',
              style: TextStyle(
                color: daysUntilDue <= 3 ? Colors.red : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getObligationColor(FinancialObligation obligation) {
    switch (obligation.type) {
      case ObligationType.bill:
        return Colors.blue;
      case ObligationType.debt:
        return Colors.red;
      case ObligationType.subscription:
        return Colors.pink;
    }
  }

  IconData _getObligationIcon(FinancialObligation obligation) {
    switch (obligation.type) {
      case ObligationType.bill:
        return Icons.receipt;
      case ObligationType.debt:
        return Icons.credit_card;
      case ObligationType.subscription:
        return Icons.subscriptions;
    }
  }
}
