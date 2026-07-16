import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/obligation_service.dart';
import 'package:financial_app/widgets/obligations/obligation_filters.dart';
import 'package:financial_app/widgets/obligations/obligation_helpers.dart';
import 'package:financial_app/widgets/obligations/obligation_item.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/utils/design_tokens.dart';

/// View for recurring obligations (subscriptions + recurring bills).
class RecurringObligationsView extends StatefulWidget {
  final String searchQuery;
  final ObligationFilters filters;

  const RecurringObligationsView({
    super.key,
    this.searchQuery = '',
    this.filters = const ObligationFilters(),
  });

  @override
  State<RecurringObligationsView> createState() =>
      _RecurringObligationsViewState();
}

class _RecurringObligationsViewState extends State<RecurringObligationsView> {
  int _refreshKey = 0;

  void _onObligationChanged() {
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<List<FinancialObligation>>(
      key: ValueKey('recurring_$_refreshKey'),
      future: getIt<ObligationService>().getObligations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: DesignTokens.primaryColor),
          );
        }

        var obligations = snapshot.data!;

        // Filter: only recurring (subscriptions or is_subscription)
        obligations =
            obligations
                .where(
                  (o) =>
                      o.type == ObligationType.subscription ||
                      o.isSubscription,
                )
                .toList();

        // Apply search
        if (widget.searchQuery.isNotEmpty) {
          final query = widget.searchQuery.toLowerCase();
          obligations =
              obligations.where((o) {
                return o.name.toLowerCase().contains(query) ||
                    (o.category?.toLowerCase().contains(query) ?? false) ||
                    o.monthlyAmount.toString().contains(query);
              }).toList();
        }

        // Apply filters
        if (widget.filters.hasFilters) {
          final f = widget.filters;
          obligations =
              obligations.where((o) {
                if (f.type != null && o.type.name != f.type) return false;
                if (f.category != null && o.category != f.category) {
                  return false;
                }
                if (f.minAmount != null && o.monthlyAmount < f.minAmount!) {
                  return false;
                }
                if (f.maxAmount != null && o.monthlyAmount > f.maxAmount!) {
                  return false;
                }
                return true;
              }).toList();
        }

        // Sort by next due
        obligations.sort((a, b) => a.dueDate.compareTo(b.dueDate));

        if (obligations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Iconsax.crown,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada langganan berulang',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: obligations.length,
          itemBuilder: (context, index) {
            final obligation = obligations[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ObligationItem(
                  obligation: obligation,
                  onTap: () => ObligationHelpers.showObligationDetails(
                    context,
                    obligation,
                  ),
                  onPaymentRecorded: _onObligationChanged,
                ),
              );
          },
        );
      },
    );
  }
}
