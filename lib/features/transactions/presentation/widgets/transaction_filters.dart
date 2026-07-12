import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/utils/design_tokens.dart';

class TransactionFilters extends StatefulWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const TransactionFilters({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  State<TransactionFilters> createState() => _TransactionFiltersState();
}

class _TransactionFiltersState extends State<TransactionFilters> {
  final List<String> _filterKeys = [
    'Semua',
    'Pemasukan',
    'Pengeluaran',
    'Hari Ini',
    'Minggu Ini',
    'Bulan Ini',
  ];

  String _getFilterLabel(String key, AppLocalizations? l10n) {
    switch (key) {
      case 'Semua':
        return l10n?.all ?? 'Semua';
      case 'Pemasukan':
        return l10n?.income ?? 'Pemasukan';
      case 'Pengeluaran':
        return l10n?.expense ?? 'Pengeluaran';
      case 'Hari Ini':
        return l10n?.today ?? 'Hari Ini';
      case 'Minggu Ini':
        return l10n?.this_week ?? 'Minggu Ini';
      case 'Bulan Ini':
        return l10n?.this_month ?? 'Bulan Ini';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filterKeys.length,
        itemBuilder: (context, index) {
          final filter = _filterKeys[index];
          final isSelected = widget.selectedFilter == filter;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                _getFilterLabel(filter, l10n),
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                widget.onFilterChanged(filter);
              },
              backgroundColor: DesignTokens.surfaceDark,
              selectedColor: DesignTokens.primaryColor,
              checkmarkColor: Colors.white,
              side: BorderSide(color: DesignTokens.borderDark),
            ),
          );
        },
      ),
    );
  }
}
