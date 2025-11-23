import 'package:flutter/material.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/obligation_service.dart';
import 'package:financial_app/widgets/obligations/obligation_helpers.dart';
import 'debt_progress_card.dart';
import 'debt_item.dart';
import 'payoff_strategy_card.dart';

class DebtsView extends StatelessWidget {
  const DebtsView({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DebtSummary>(
      future: ObligationService().getDebtSummary(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());

        final summary = snapshot.data!;

        if (summary.debts.isEmpty) {
          return Center(
            child: Text(
              'Tidak ada hutang aktif',
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
                padding: EdgeInsets.all(16),
                itemCount: summary.debts.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap:
                        () => ObligationHelpers.showObligationDetails(
                          context,
                          summary.debts[index],
                        ),
                    child: DebtItem(debt: summary.debts[index]),
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
