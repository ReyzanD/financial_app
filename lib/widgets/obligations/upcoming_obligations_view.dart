import 'package:flutter/material.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/obligation_service.dart';
import 'package:financial_app/widgets/obligations/obligation_helpers.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'obligation_item.dart';

class UpcomingObligationsView extends StatelessWidget {
  final String searchQuery;

  const UpcomingObligationsView({super.key, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FinancialObligation>>(
      future: ObligationService().getUpcomingObligations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var obligations = snapshot.data!;

        // Apply search filter
        if (searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          obligations =
              obligations.where((o) {
                return o.name.toLowerCase().contains(query) ||
                    (o.category?.toLowerCase().contains(query) ?? false) ||
                    o.monthlyAmount.toString().contains(query);
              }).toList();
        }

        if (obligations.isEmpty) {
          return Center(
            child: Text(
              searchQuery.isNotEmpty
                  ? AppLocalizations.of(context)!.no_search_results
                  : AppLocalizations.of(context)!.no_upcoming,
              style: TextStyle(color: Colors.grey[400]),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: obligations.length,
          itemBuilder: (context, index) {
            return ObligationItem(
              obligation: obligations[index],
              onTap:
                  () => ObligationHelpers.showObligationDetails(
                    context,
                    obligations[index],
                  ),
            );
          },
        );
      },
    );
  }
}
