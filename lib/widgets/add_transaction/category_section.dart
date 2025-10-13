import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class CategorySection extends StatelessWidget {
  final String selectedType;
  final String? selectedCategory;
  final Function(String) onCategorySelected;

  const CategorySection({
    super.key,
    required this.selectedType,
    required this.selectedCategory,
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

  @override
  Widget build(BuildContext context) {
    final categories = _categories[selectedType] ?? [];

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
        if (categories.isEmpty)
          Text(
            'Tidak ada kategori tersedia',
            style: GoogleFonts.poppins(color: Colors.grey[500]),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                categories.map((category) {
                  final isSelected = selectedCategory == category['id'];

                  return GestureDetector(
                    onTap: () => onCategorySelected(category['id'] as String),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? (category['color'] as Color).withValues(
                                  alpha: .2,
                                  red: 0.2,
                                  green: 0.2,
                                  blue: 0.3,
                                )
                                : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isSelected
                                  ? category['color'] as Color
                                  : Colors.grey[700]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category['icon'] as IconData,
                            size: 16,
                            color:
                                isSelected
                                    ? category['color'] as Color
                                    : Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            category['name'] as String,
                            style: GoogleFonts.poppins(
                              color:
                                  isSelected
                                      ? category['color'] as Color
                                      : Colors.grey[500],
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
