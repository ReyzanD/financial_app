import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/utils/formatters.dart';

class QuickAmountSelector extends StatelessWidget {
  final List<double> amounts;
  final Function(double) onAmountSelected;

  const QuickAmountSelector({
    super.key,
    required this.amounts,
    required this.onAmountSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: amounts.map((amount) => _buildAmountChip(amount)).toList(),
    );
  }

  Widget _buildAmountChip(double amount) {
    return InkWell(
      onTap: () => onAmountSelected(amount),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF8B5FBF).withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF8B5FBF).withOpacity(0.5)),
        ),
        child: Text(
          CurrencyFormatter.formatRupiah(amount.toInt()),
          style: GoogleFonts.poppins(
            color: const Color(0xFF8B5FBF),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
