import 'package:flutter/material.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/obligation_service.dart';
import 'subscription_item.dart';

class SubscriptionsView extends StatelessWidget {
  const SubscriptionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FinancialObligation>>(
      future: ObligationService().getUpcomingObligations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());

        final subscriptions =
            snapshot.data!.where((o) => o.isSubscription).toList();

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: subscriptions.length,
          itemBuilder: (context, index) {
            return SubscriptionItem(subscription: subscriptions[index]);
          },
        );
      },
    );
  }
}
