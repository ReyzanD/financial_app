import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final List<String> _filters = [
    'Semua',
    'Pemasukan',
    'Pengeluaran',
    'Hari Ini',
    'Minggu Ini',
    'Bulan Ini',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = widget.selectedFilter == filter;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter,
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
