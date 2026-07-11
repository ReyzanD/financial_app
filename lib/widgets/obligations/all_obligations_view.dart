import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/obligation_service.dart';
import 'package:financial_app/widgets/obligations/obligation_filters.dart';
import 'package:financial_app/widgets/obligations/obligation_helpers.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'obligation_item.dart';
import 'package:financial_app/utils/design_tokens.dart';

class AllObligationsView extends StatefulWidget {
  final String searchQuery;
  final ObligationFilters filters;

  const AllObligationsView({super.key, this.searchQuery = '', this.filters = const ObligationFilters()});

  @override
  State<AllObligationsView> createState() => _AllObligationsViewState();
}

/// Lightweight item model for flat lazy list
enum _SectionItemType { header, obligation, spacing }

class _SectionItem {
  final _SectionItemType type;
  final FinancialObligation? obligation;
  final String? title;
  final int? count;

  const _SectionItem.header(this.title, this.count)
    : type = _SectionItemType.header,
      obligation = null;

  const _SectionItem.obligation(this.obligation)
    : type = _SectionItemType.obligation,
      title = null,
      count = null;

  const _SectionItem.spacing()
    : type = _SectionItemType.spacing,
      obligation = null,
      title = null,
      count = null;
}

class _AllObligationsViewState extends State<AllObligationsView> {
  int _refreshKey = 0;

  void _refreshData() {
    setState(() {
      _refreshKey++;
    });
  }

  /// Build a flat list of section items for lazy rendering
  List<_SectionItem> _buildSectionItems(
    List<FinancialObligation> bills,
    List<FinancialObligation> subscriptions,
    List<FinancialObligation> debts,
  ) {
    final items = <_SectionItem>[];

    void addSection(String title, List<FinancialObligation> list) {
      items.add(_SectionItem.header(title, list.length));
      items.add(const _SectionItem.spacing());
      for (final obligation in list) {
        items.add(_SectionItem.obligation(obligation));
      }
      items.add(const _SectionItem.spacing());
    }

    if (bills.isNotEmpty) {
      addSection(AppLocalizations.of(context)!.bill, bills);
    }
    if (subscriptions.isNotEmpty) {
      addSection(AppLocalizations.of(context)!.subscription, subscriptions);
    }
    if (debts.isNotEmpty) {
      addSection(AppLocalizations.of(context)!.debt, debts);
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FinancialObligation>>(
      key: ValueKey('obligations_$_refreshKey'),
      future: ObligationService().getObligations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var obligations = snapshot.data!;

        // Apply filters
        if (widget.filters.hasFilters) {
          final f = widget.filters;
          obligations = obligations.where((o) {
            if (f.type != null && o.type.name != f.type) return false;
            if (f.category != null && o.category != f.category) return false;
            if (f.status != null) {
              if (f.status == 'active' && o.daysUntilDue <= 0) return false;
              if (f.status == 'overdue' && o.daysUntilDue >= 0) return false;
            }
            if (f.minAmount != null && o.monthlyAmount < f.minAmount!) return false;
            if (f.maxAmount != null && o.monthlyAmount > f.maxAmount!) return false;
            if (f.startDate != null && o.dueDate.isBefore(f.startDate!)) return false;
            if (f.endDate != null && o.dueDate.isAfter(f.endDate!)) return false;
            return true;
          }).toList();
        }

        if (obligations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.no_obligations,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.add_obligation_hint,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        // Group obligations by type
        final bills =
            obligations.where((o) => o.type == ObligationType.bill).toList();
        final subscriptions =
            obligations
                .where((o) => o.type == ObligationType.subscription)
                .toList();
        final debts =
            obligations.where((o) => o.type == ObligationType.debt).toList();

        final items = _buildSectionItems(bills, subscriptions, debts);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            switch (item.type) {
              case _SectionItemType.header:
                return _buildSectionHeader(item.title!, item.count!);
              case _SectionItemType.spacing:
                return const SizedBox(height: 12);
              case _SectionItemType.obligation:
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ObligationItem(
                    obligation: item.obligation!,
                    onTap:
                        () => ObligationHelpers.showObligationDetails(
                          context,
                          item.obligation!,
                        ),
                    onPaymentRecorded: _refreshData,
                  ),
                );
            }
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: DesignTokens.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: GoogleFonts.poppins(
              color: DesignTokens.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
