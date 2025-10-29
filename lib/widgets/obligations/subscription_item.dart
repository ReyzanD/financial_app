import 'package:flutter/material.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/utils/formatters.dart';

class SubscriptionItem extends StatelessWidget {
  final FinancialObligation subscription;

  const SubscriptionItem({super.key, required this.subscription});

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
            color: Colors.pink.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.subscriptions, color: Colors.pink),
        ),
        title: Text(subscription.name, style: TextStyle(color: Colors.white)),
        subtitle: Text(
          '${subscription.subscriptionCycle}',
          style: TextStyle(color: Colors.grey),
        ),
        trailing: Text(
          CurrencyFormatter.formatRupiah(subscription.monthlyAmount.toInt()),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
