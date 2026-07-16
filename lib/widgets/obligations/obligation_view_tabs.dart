import 'package:flutter/material.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/utils/design_tokens.dart';

class ObligationViewTabs extends StatelessWidget {
  final String selectedView;
  final Function(String) onViewChanged;

  const ObligationViewTabs({super.key, required this.selectedView, required this.onViewChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildViewTab(context, l10n.all, 'all'),
            _buildViewTab(context, l10n.upcoming, 'upcoming'),
            _buildViewTab(context, l10n.overdue, 'overdue'),
            _buildViewTab(context, l10n.debt, 'debts'),
            _buildViewTab(context, 'Berulang', 'recurring'),
            _buildViewTab(context, l10n.subscription, 'subscriptions'),
          ],
        ),
      ),
    );
  }

  Widget _buildViewTab(BuildContext context, String label, String value) {
    final isSelected = selectedView == value;

    return GestureDetector(
      onTap: () => onViewChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: isSelected ? DesignTokens.primaryColor : Colors.transparent, width: 2),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? DesignTokens.primaryColor : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
