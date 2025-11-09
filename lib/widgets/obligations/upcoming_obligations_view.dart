import 'package:flutter/material.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/obligation_service.dart';
import 'obligation_item.dart';

class UpcomingObligationsView extends StatelessWidget {
  final VoidCallback onObligationTap;

  const UpcomingObligationsView({super.key, required this.onObligationTap});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FinancialObligation>>(
      future: ObligationService().getUpcomingObligations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final obligations = snapshot.data!;

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: obligations.length,
          itemBuilder: (context, index) {
            return ObligationItem(
              obligation: obligations[index],
              onTap: () => onObligationTap,
            );
          },
        );
      },
    );
  }
}
