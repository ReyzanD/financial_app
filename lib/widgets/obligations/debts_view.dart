import 'package:flutter/material.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/obligation_service.dart';
import 'package:financial_app/widgets/obligations/obligation_helpers.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'debt_progress_card.dart';
import 'debt_item.dart';
import 'payoff_strategy_card.dart';

class DebtsView extends StatelessWidget {
  final String searchQuery;

  const DebtsView({super.key, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DebtSummary>(
      future: ObligationService().getDebtSummary(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final summary = snapshot.data!;
        var debts = summary.debts;

        // Apply search filter
        if (searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          debts =
              debts.where((d) {
                return d.name.toLowerCase().contains(query) ||
                    (d.category?.toLowerCase().contains(query) ?? false) ||
                    d.monthlyAmount.toString().contains(query);
              }).toList();
        }

        if (debts.isEmpty) {
          return Center(
            child: Text(
              searchQuery.isNotEmpty
                  ? AppLocalizations.of(context)!.no_search_results
                  : AppLocalizations.of(context)!.no_debts,
              style: TextStyle(color: Colors.grey[400]),
            ),
          );
        }

        return Column(
          children: [
            // Debt Progress
            DebtProgressCard(summary: summary),

            // Debt List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: debts.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap:
                        () => ObligationHelpers.showObligationDetails(
                          context,
                          debts[index],
                        ),
                    child: DebtItem(debt: debts[index]),
                  );
                },
              ),
            ),

            // Payoff Strategy
            PayoffStrategyCard(),
          ],
        );
      },
    );
  }
}
