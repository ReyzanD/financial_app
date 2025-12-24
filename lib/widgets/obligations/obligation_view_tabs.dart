import 'package:flutter/material.dart';
import 'package:financial_app/l10n/app_localizations.dart';

class ObligationViewTabs extends StatelessWidget {
  final String selectedView;
  final Function(String) onViewChanged;

  const ObligationViewTabs({
    super.key,
    required this.selectedView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildViewTab(context, AppLocalizations.of(context)!.all, 'all'),
          _buildViewTab(context, AppLocalizations.of(context)!.upcoming, 'upcoming'),
          _buildViewTab(context, AppLocalizations.of(context)!.debt, 'debts'),
          _buildViewTab(context, AppLocalizations.of(context)!.subscription, 'subscriptions'),
        ],
      ),
    );
  }

  Widget _buildViewTab(BuildContext context, String label, String value) {
    final isSelected = selectedView == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => onViewChanged(value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Color(0xFF8B5FBF) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Color(0xFF8B5FBF) : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
