import 'package:flutter/material.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/obligation_service.dart';
import 'package:financial_app/widgets/obligations/obligation_filters.dart';
import 'package:financial_app/widgets/obligations/obligation_helpers.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'debt_progress_card.dart';
import 'debt_item.dart';
import 'payoff_strategy_card.dart';

class DebtsView extends StatelessWidget {
  final String searchQuery;
  final ObligationFilters filters;

  const DebtsView({
    super.key,
    this.searchQuery = '',
    this.filters = const ObligationFilters(),
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DebtSummary>(
      future: getIt<ObligationService>().getDebtSummary(),
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

        // Apply obligation filters
        if (filters.hasFilters) {
          final f = filters;
          debts =
              debts.where((d) {
                if (f.type != null && d.type.name != f.type) return false;
                if (f.category != null && d.category != f.category)
                  return false;
                if (f.status != null) {
                  if (f.status == 'active' && d.daysUntilDue <= 0) return false;
                  if (f.status == 'overdue' && d.daysUntilDue >= 0)
                    return false;
                }
                if (f.minAmount != null && d.monthlyAmount < f.minAmount!)
                  return false;
                if (f.maxAmount != null && d.monthlyAmount > f.maxAmount!)
                  return false;
                if (f.startDate != null && d.dueDate.isBefore(f.startDate!))
                  return false;
                if (f.endDate != null && d.dueDate.isAfter(f.endDate!))
                  return false;
                return true;
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
                padding: const EdgeInsets.all(DesignTokens.spacing4),
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
