import 'package:flutter/material.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/obligation_service.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/design_tokens.dart';

class ObligationSummaryCards extends StatelessWidget {
  const ObligationSummaryCards({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ObligationService().getObligationsSummary(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();

        final summary = snapshot.data!;
        final l10n = AppLocalizations.of(context);

        return Container(
          padding: const EdgeInsets.all(DesignTokens.spacing4),
          child: Row(
            children: [
              // Monthly Obligations
              Expanded(
                child: _buildSummaryCard(
                  l10n?.this_month ?? 'Bulan Ini',
                  CurrencyFormatter.formatRupiah(
                    (summary['monthlyTotal'] as num?)?.toInt() ?? 0,
                  ),
                  Colors.blue,
                  Iconsax.calendar,
                ),
              ),
              SizedBox(width: 12),

              // Total Debt
              Expanded(
                child: _buildSummaryCard(
                  l10n?.total_debt ?? 'Total Hutang',
                  CurrencyFormatter.formatRupiah(
                    (summary['totalDebt'] as num?)?.toInt() ?? 0,
                  ),
                  Colors.red,
                  Iconsax.card,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Card(
      color: DesignTokens.surfaceDark,
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(width: 8),
                Text(title, style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
