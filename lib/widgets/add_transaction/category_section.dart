import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/models/category_model.dart';
import 'package:financial_app/utils/design_tokens.dart';

class CategorySection extends StatelessWidget {
  final String selectedType;
  final String? selectedCategory; // Now stores category_id (UUID)
  final List<CategoryModel> categories;
  final bool isLoading;
  final Function(String) onCategorySelected;

  const CategorySection({
    super.key,
    required this.selectedType,
    required this.selectedCategory,
    required this.categories,
    required this.isLoading,
    required this.onCategorySelected,
  });

  // Map category names to icons (fallback for display)
  IconData _getCategoryIcon(String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('food') || nameLower.contains('makanan')) {
      return Iconsax.shop;
    }
    if (nameLower.contains('transport') || nameLower.contains('transportasi')) {
      return Iconsax.car;
    }
    if (nameLower.contains('shop') || nameLower.contains('belanja')) {
      return Iconsax.shopping_cart;
    }
    if (nameLower.contains('entertain') || nameLower.contains('hiburan')) {
      return Iconsax.game;
    }
    if (nameLower.contains('bill') || nameLower.contains('tagihan')) {
      return Iconsax.receipt;
    }
    if (nameLower.contains('health') || nameLower.contains('kesehatan')) {
      return Iconsax.health;
    }
    if (nameLower.contains('salary') || nameLower.contains('gaji')) {
      return Iconsax.wallet;
    }
    if (nameLower.contains('freelance')) return Iconsax.code;
    if (nameLower.contains('invest') || nameLower.contains('investasi')) {
      return Iconsax.chart;
    }
    if (nameLower.contains('bonus')) return Iconsax.gift;
    return Iconsax.receipt; // default icon
  }

  Color _parseColor(String colorStr) {
    if (colorStr.isEmpty) return Colors.grey;
    try {
      // Remove # if present and parse hex color
      final hex = colorStr.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Filter categories by type
    final filteredCategories = categories.where((cat) => cat.type == selectedType).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.category ?? 'Kategori',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: DesignTokens.spacing3),
        if (isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: CircularProgressIndicator(color: DesignTokens.primaryColor, strokeWidth: 2),
            ),
          )
        else if (filteredCategories.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: DesignTokens.surfaceDark,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              border: Border.all(color: DesignTokens.borderDark),
            ),
            child: Text(
              l10n?.no_categories_available ?? 'Tidak ada kategori tersedia',
              style: GoogleFonts.poppins(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                filteredCategories.map((category) {
                  final isSelected = selectedCategory == category.id;
                  final categoryColor = _parseColor(category.color);

                  return GestureDetector(
                    onTap: () => onCategorySelected(category.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? categoryColor.withValues(alpha: 0.2) : DesignTokens.surfaceDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? categoryColor : Colors.grey[700]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(category.name),
                            size: 16,
                            color: isSelected ? categoryColor : Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            category.name,
                            style: GoogleFonts.poppins(
                              color: isSelected ? categoryColor : Colors.grey[500],
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
      ],
    );
  }
}
