import 'package:flutter/material.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/obligation_service.dart';
import 'package:financial_app/widgets/obligations/obligation_helpers.dart';
import 'obligation_item.dart';

class UpcomingObligationsView extends StatelessWidget {
  const UpcomingObligationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FinancialObligation>>(
      future: ObligationService().getUpcomingObligations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final obligations = snapshot.data!;

        if (obligations.isEmpty) {
          return Center(
            child: Text(
              'Tidak ada kewajiban yang akan datang',
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
