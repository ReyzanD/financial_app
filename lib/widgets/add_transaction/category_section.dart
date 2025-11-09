import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class CategorySection extends StatelessWidget {
  final String selectedType;
  final String? selectedCategory; // Now stores category_id (UUID)
  final List<Map<String, dynamic>> categories; // Categories from API
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

  static const Map<String, List<Map<String, dynamic>>> _categories = {
    'income': [
      {
        'id': 'salary',
        'name': 'Gaji',
        'icon': Iconsax.wallet,
        'color': Colors.green,
      },
      {
        'id': 'freelance',
        'name': 'Freelance',
        'icon': Iconsax.code,
        'color': Colors.blue,
      },
      {
        'id': 'investment',
        'name': 'Investasi',
        'icon': Iconsax.chart,
        'color': Colors.purple,
      },
      {
        'id': 'bonus',
        'name': 'Bonus',
        'icon': Iconsax.gift,
        'color': Colors.orange,
      },
    ],
    'expense': [
      {
        'id': 'food',
        'name': 'Makanan & Minuman',
        'icon': Iconsax.shop,
        'color': Colors.red,
      },
      {
        'id': 'transport',
        'name': 'Transportasi',
        'icon': Iconsax.car,
        'color': Colors.orange,
      },
      {
        'id': 'shopping',
        'name': 'Belanja',
        'icon': Iconsax.shopping_cart,
        'color': Colors.blue,
      },
      {
        'id': 'entertainment',
        'name': 'Hiburan',
        'icon': Iconsax.game,
        'color': Colors.purple,
      },
      {
        'id': 'bills',
        'name': 'Tagihan',
        'icon': Iconsax.receipt,
        'color': Colors.yellow,
      },
      {
        'id': 'health',
        'name': 'Kesehatan',
        'icon': Iconsax.health,
        'color': Colors.green,
      },
    ],
  };

  // Map category names to icons (fallback for display)
  IconData _getCategoryIcon(String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('food') || nameLower.contains('makanan'))
      return Iconsax.shop;
    if (nameLower.contains('transport') || nameLower.contains('transportasi'))
      return Iconsax.car;
    if (nameLower.contains('shop') || nameLower.contains('belanja'))
      return Iconsax.shopping_cart;
    if (nameLower.contains('entertain') || nameLower.contains('hiburan'))
      return Iconsax.game;
    if (nameLower.contains('bill') || nameLower.contains('tagihan'))
      return Iconsax.receipt;
    if (nameLower.contains('health') || nameLower.contains('kesehatan'))
      return Iconsax.health;
    if (nameLower.contains('salary') || nameLower.contains('gaji'))
      return Iconsax.wallet;
    if (nameLower.contains('freelance')) return Iconsax.code;
    if (nameLower.contains('invest') || nameLower.contains('investasi'))
      return Iconsax.chart;
    if (nameLower.contains('bonus')) return Iconsax.gift;
    return Iconsax.receipt; // default icon
  }

  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return Colors.grey;
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
    // Filter categories by type
    final filteredCategories =
        categories.where((cat) {
          final type = cat['type']?.toString().toLowerCase() ?? '';
          return type == selectedType;
        }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: Color(0xFF8B5FBF),
                strokeWidth: 2,
              ),
            ),
          )
        else if (filteredCategories.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Text(
              'Tidak ada kategori tersedia untuk ${selectedType == "income" ? "pemasukan" : "pengeluaran"}',
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
                  final categoryId = category['id']?.toString() ?? '';
                  final isSelected = selectedCategory == categoryId;
                  final categoryName =
                      category['name']?.toString() ?? 'Unknown';
                  final categoryColor = _parseColor(
                    category['color']?.toString(),
                  );
                  final categoryIcon = _getCategoryIcon(categoryName);

                  return GestureDetector(
                    onTap: () => onCategorySelected(categoryId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? categoryColor.withOpacity(0.2)
                                : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? categoryColor : Colors.grey[700]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            categoryIcon,
                            size: 16,
                            color:
                                isSelected ? categoryColor : Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            categoryName,
                            style: GoogleFonts.poppins(
                              color:
                                  isSelected ? categoryColor : Colors.grey[500],
                              fontSize: 12,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
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
