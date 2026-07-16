import 'package:flutter/material.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/obligation_service.dart';
import 'package:financial_app/widgets/obligations/obligation_filters.dart';
import 'package:financial_app/widgets/obligations/obligation_helpers.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'obligation_item.dart';

class UpcomingObligationsView extends StatelessWidget {
  final String searchQuery;
  final ObligationFilters filters;

  const UpcomingObligationsView({
    super.key,
    this.searchQuery = '',
    this.filters = const ObligationFilters(),
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FinancialObligation>>(
      future: getIt<ObligationService>().getUpcomingObligations(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              AppLocalizations.of(context)?.failed_to_load_data ??
                  'Gagal Memuat Data',
              style: TextStyle(color: Colors.grey[400]),
            ),
          );
        }
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

        // Apply obligation filters
        if (filters.hasFilters) {
          final f = filters;
          obligations =
              obligations.where((o) {
                if (f.type != null && o.type.name != f.type) return false;
                if (f.category != null && o.category != f.category)
                  return false;
                if (f.status != null) {
                  if (f.status == 'active' && o.daysUntilDue <= 0) return false;
                  if (f.status == 'overdue' && o.daysUntilDue >= 0)
                    return false;
                }
                if (f.minAmount != null && o.monthlyAmount < f.minAmount!)
                  return false;
                if (f.maxAmount != null && o.monthlyAmount > f.maxAmount!)
                  return false;
                if (f.startDate != null && o.dueDate.isBefore(f.startDate!))
                  return false;
                if (f.endDate != null && o.dueDate.isAfter(f.endDate!))
                  return false;
                return true;
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
          padding: EdgeInsets.all(DesignTokens.spacing4),
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
