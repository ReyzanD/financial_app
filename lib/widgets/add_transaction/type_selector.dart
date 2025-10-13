import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              'Pengeluaran',
              'expense',
              Iconsax.arrow_down,
              Colors.red,
            ),
          ),
          Expanded(
            child: _buildTypeButton(
              'Pemasukan',
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
