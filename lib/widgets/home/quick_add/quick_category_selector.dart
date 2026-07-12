import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/utils/design_tokens.dart';

class QuickCategorySelector extends StatelessWidget {
  final List<dynamic> categories;
  final Function(String) onCategorySelected;
  final bool isLoading;

  const QuickCategorySelector({
    super.key,
    required this.categories,
    required this.onCategorySelected,
    this.isLoading = false,
  });

  /// Normalizes a category map to use clean keys ('id', 'name') regardless
  /// of whether the source map uses suffixed DB keys (e.g. 'category_id_232143').
  static Map<String, dynamic> _normalize(Map<String, dynamic> src) {
    return {
      'id':
          src['id']?.toString() ??
          src['category_id']?.toString() ??
          src['category_id_232143']?.toString() ??
          src.values
              .firstWhere(
                (v) => v.toString().startsWith('cat_'),
                orElse: () => '',
              )
              .toString(),
      'name':
          (src['name'] ??
                  src['category_name'] ??
                  src['name_232143']?.toString() ??
                  src.values.firstWhere(
                    (v) => v is String && !v.toString().startsWith('cat_'),
                    orElse: () => '',
                  ))
              .toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: DesignTokens.primaryColor),
        ),
      );
    }

    if (categories.isEmpty) {
      return Center(
        child: Text(
          'No categories available',
          style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          categories
              .map(
                (c) => _buildCategoryChip(
                  c is Map<String, dynamic> ? _normalize(c) : c,
                ),
              )
              .toList(),
    );
  }

  Widget _buildCategoryChip(dynamic category) {
    final id =
        category is Map<String, dynamic>
            ? (category['id']?.toString() ?? '')
            : category.toString();
    final name =
        category is Map<String, dynamic>
            ? (category['name']?.toString() ?? 'Unknown')
            : category.toString();

    return InkWell(
      onTap: () => onCategorySelected(id),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: DesignTokens.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DesignTokens.borderDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.category, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 6),
            Text(
              name,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
