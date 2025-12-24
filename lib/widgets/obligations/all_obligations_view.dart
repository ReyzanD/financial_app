import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/obligation_service.dart';
import 'package:financial_app/widgets/obligations/obligation_helpers.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'obligation_item.dart';

class AllObligationsView extends StatefulWidget {
  final String searchQuery;

  const AllObligationsView({super.key, this.searchQuery = ''});

  @override
  State<AllObligationsView> createState() => _AllObligationsViewState();
}

class _AllObligationsViewState extends State<AllObligationsView> {
  int _refreshKey = 0;

  void _refreshData() {
    setState(() {
      _refreshKey++;
    });
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

        final obligations = snapshot.data!;

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
        final debts =
            obligations.where((o) => o.type == ObligationType.debt).toList();
        final subscriptions =
            obligations
                .where((o) => o.type == ObligationType.subscription)
                .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Bills Section
            if (bills.isNotEmpty) ...[
              _buildSectionHeader(
                AppLocalizations.of(context)!.bill,
                bills.length,
              ),
              const SizedBox(height: 8),
              ...bills.map(
                (obligation) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ObligationItem(
                    obligation: obligation,
                    onTap:
                        () => ObligationHelpers.showObligationDetails(
                          context,
                          obligation,
                        ),
                    onPaymentRecorded: _refreshData,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Subscriptions Section
            if (subscriptions.isNotEmpty) ...[
              _buildSectionHeader(
                AppLocalizations.of(context)!.subscription,
                subscriptions.length,
              ),
              const SizedBox(height: 8),
              ...subscriptions.map(
                (obligation) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ObligationItem(
                    obligation: obligation,
                    onTap:
                        () => ObligationHelpers.showObligationDetails(
                          context,
                          obligation,
                        ),
                    onPaymentRecorded: _refreshData,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Debts Section
            if (debts.isNotEmpty) ...[
              _buildSectionHeader(
                AppLocalizations.of(context)!.debt,
                debts.length,
              ),
              const SizedBox(height: 8),
              ...debts.map(
                (obligation) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ObligationItem(
                    obligation: obligation,
                    onTap:
                        () => ObligationHelpers.showObligationDetails(
                          context,
                          obligation,
                        ),
                    onPaymentRecorded: _refreshData,
                  ),
                ),
              ),
            ],
          ],
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
            color: const Color(0xFF8B5FBF).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: GoogleFonts.poppins(
              color: const Color(0xFF8B5FBF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
