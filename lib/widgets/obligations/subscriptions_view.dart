import 'package:flutter/material.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/obligation_service.dart';
import 'package:financial_app/widgets/obligations/obligation_helpers.dart';
import 'subscription_item.dart';

class SubscriptionsView extends StatelessWidget {
  const SubscriptionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FinancialObligation>>(
      future: ObligationService().getSubscriptions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());

        final subscriptions = snapshot.data!;

        if (subscriptions.isEmpty) {
          return Center(
            child: Text(
              'Tidak ada langganan aktif',
              style: TextStyle(color: Colors.grey[400]),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: subscriptions.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap:
                  () => ObligationHelpers.showObligationDetails(
                    context,
                    subscriptions[index],
                  ),
              child: SubscriptionItem(subscription: subscriptions[index]),
            );
          },
        );
      },
    );
  }
}
