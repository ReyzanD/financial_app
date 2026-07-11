import 'package:flutter/material.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/obligation_service.dart';
import 'package:financial_app/widgets/obligations/obligation_filters.dart';
import 'package:financial_app/widgets/obligations/obligation_helpers.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'subscription_item.dart';

class SubscriptionsView extends StatelessWidget {
  final String searchQuery;
  final ObligationFilters filters;

  const SubscriptionsView({super.key, this.searchQuery = '', this.filters = const ObligationFilters()});

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

        // Apply obligation filters
        if (filters.hasFilters) {
          final f = filters;
          subscriptions = subscriptions.where((s) {
            if (f.type != null && s.type.name != f.type) return false;
            if (f.category != null && s.category != f.category) return false;
            if (f.status != null) {
              if (f.status == 'active' && s.daysUntilDue <= 0) return false;
              if (f.status == 'overdue' && s.daysUntilDue >= 0) return false;
            }
            if (f.minAmount != null && s.monthlyAmount < f.minAmount!) return false;
            if (f.maxAmount != null && s.monthlyAmount > f.maxAmount!) return false;
            if (f.startDate != null && s.dueDate.isBefore(f.startDate!)) return false;
            if (f.endDate != null && s.dueDate.isAfter(f.endDate!)) return false;
            return true;
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
