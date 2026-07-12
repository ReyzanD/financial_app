import 'package:flutter/material.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/utils/design_tokens.dart';

class PeriodSelector extends StatefulWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;

  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  State<PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<PeriodSelector> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final periods = [
      l10n?.this_week ?? 'Minggu Ini',
      l10n?.this_month ?? 'Bulan Ini',
      '3 Bulan',
      l10n?.this_year ?? 'Tahun Ini',
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: periods.length,
        itemBuilder: (context, index) {
          final period = periods[index];
          final isSelected = widget.selectedPeriod == period;

          return GestureDetector(
            onTap: () {
              widget.onPeriodChanged(period);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? DesignTokens.primaryColor
                        : DesignTokens.surfaceDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected
                          ? DesignTokens.primaryColor
                          : DesignTokens.borderDark,
                ),
              ),
              child: Text(
                period,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : Colors.grey[400],
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
