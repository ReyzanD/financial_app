import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
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
          categories.map((category) => _buildCategoryChip(category)).toList(),
    );
  }

  Widget _buildCategoryChip(dynamic category) {
    return InkWell(
      onTap: () => onCategorySelected(category['id'].toString()),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.category, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 6),
            Text(
              category['name'].toString(),
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
