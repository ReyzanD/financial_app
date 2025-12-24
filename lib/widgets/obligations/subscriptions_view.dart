import 'package:flutter/material.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/obligation_service.dart';
import 'package:financial_app/widgets/obligations/obligation_helpers.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'subscription_item.dart';

class SubscriptionsView extends StatelessWidget {
  final String searchQuery;

  const SubscriptionsView({super.key, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FinancialObligation>>(
      future: ObligationService().getSubscriptions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var subscriptions = snapshot.data!;

        // Apply search filter
        if (searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          subscriptions =
              subscriptions.where((s) {
                return s.name.toLowerCase().contains(query) ||
                    (s.category?.toLowerCase().contains(query) ?? false) ||
                    s.monthlyAmount.toString().contains(query);
              }).toList();
        }

        if (subscriptions.isEmpty) {
          return Center(
            child: Text(
              searchQuery.isNotEmpty
                  ? AppLocalizations.of(context)!.no_search_results
                  : AppLocalizations.of(context)!.no_subscriptions,
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
