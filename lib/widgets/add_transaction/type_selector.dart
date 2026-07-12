import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/utils/design_tokens.dart';

class TypeSelector extends StatelessWidget {
  final String selectedType;
  final Function(String) onTypeChanged;

  const TypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              l10n?.expense ?? 'Pengeluaran',
              'expense',
              Iconsax.arrow_down,
              Colors.red,
            ),
          ),
          Expanded(
            child: _buildTypeButton(
              l10n?.income ?? 'Pemasukan',
              'income',
              Iconsax.arrow_up,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(
    String label,
    String type,
    IconData icon,
    Color color,
  ) {
    final isSelected = selectedType == type;

    return GestureDetector(
      onTap: () => onTypeChanged(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: color) : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey[500], size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? color : Colors.grey[500],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
