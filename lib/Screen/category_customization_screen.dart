import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/category_customization_service.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';

class CategoryCustomizationScreen extends StatefulWidget {
  const CategoryCustomizationScreen({super.key});

  @override
  State<CategoryCustomizationScreen> createState() => _CategoryCustomizationScreenState();
}

class _CategoryCustomizationScreenState extends State<CategoryCustomizationScreen> {
  final CategoryCustomizationService _categoryService = CategoryCustomizationService();

  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _defaultCategories = [];
  List<dynamic> _customCategories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final results = await Future.wait([
        _categoryService.getAllCategoriesWithCustomizations(),
        _categoryService.getCustomCategories(),
      ]);

      if (!mounted) return;

      final allCategories = results[0] as List<dynamic>;
      final customCategories = results[1] as List<dynamic>;

      setState(() {
        _defaultCategories = allCategories.where((c) {
          final isSystemDefault = (c['is_system_default_232143'] ?? c['is_system_default'] as int? ?? 0) == 1;
          return isSystemDefault;
        }).toList();
        _customCategories = customCategories;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Color _getCategoryColor(String? color) {
    if (color == null || color.isEmpty) return DesignTokens.primaryColor;
    try {
      return Color(int.parse(color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return DesignTokens.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l10n),
            const OfflineIndicator(),
            Expanded(
              child: RefreshIndicator(
                color: DesignTokens.primaryColor,
                backgroundColor: DesignTokens.surfaceDark,
                onRefresh: _loadData,
                child: _buildBody(context, l10n),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'categories_fab',
        backgroundColor: DesignTokens.primaryColor,
        onPressed: _showAddCategoryModal,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Iconsax.arrow_left, color: DesignTokens.textPrimaryDark),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            l10n?.category ?? 'Kategori',
            style: GoogleFonts.poppins(
              color: DesignTokens.textPrimaryDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: DesignTokens.surfaceDark,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              border: Border.all(color: DesignTokens.borderDark),
            ),
            child: Text(
              '${_defaultCategories.length + _customCategories.length} ${l10n?.total_categories ?? 'kategori'}',
              style: GoogleFonts.poppins(
                color: DesignTokens.textSecondaryDark,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations? l10n) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryColor),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(context, l10n);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_customCategories.isNotEmpty) ...[
          Text(
            'Custom Categories',
            style: GoogleFonts.poppins(
              color: DesignTokens.textPrimaryDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._customCategories.map((category) {
            return _buildCategoryCard(context, category, l10n, isCustom: true);
          }),
          const SizedBox(height: 16),
        ],
        Text(
          'Default Categories',
          style: GoogleFonts.poppins(
            color: DesignTokens.textPrimaryDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ..._defaultCategories.map((category) {
          return _buildCategoryCard(context, category, l10n, isCustom: false);
        }),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, dynamic category, AppLocalizations? l10n, {required bool isCustom}) {
    final name = category['name_232143'] ?? category['name'] ?? '';
    final type = category['type_232143'] ?? category['type'] ?? '';
    final icon = category['icon_232143'] ?? category['icon'] ?? 'category';
    final color = category['color_232143'] ?? category['color'] ?? '#8B5FBF';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: DesignTokens.borderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getCategoryColor(color).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            ),
            child: Icon(
              _getIconData(icon),
              color: _getCategoryColor(color),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    color: DesignTokens.textPrimaryDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  type == 'income' ? 'Income' : 'Expense',
                  style: GoogleFonts.poppins(
                    color: DesignTokens.textSecondaryDark,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (isCustom)
            InkWell(
              onTap: () => _deleteCategory(category),
              child: Icon(
                Iconsax.trash,
                size: 16,
                color: DesignTokens.errorColor,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Iconsax.coffee;
      case 'directions_car':
        return Iconsax.car;
      case 'shopping_cart':
        return Iconsax.shopping_cart;
      case 'movie':
        return Iconsax.video;
      case 'receipt':
        return Iconsax.receipt;
      case 'local_hospital':
        return Iconsax.health;
      case 'school':
        return Iconsax.book;
      case 'work':
        return Iconsax.briefcase;
      case 'laptop':
        return Iconsax.monitor;
      case 'trending_up':
        return Iconsax.chart_1;
      default:
        return Iconsax.category;
    }
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations? l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.warning_2,
            size: 64,
            color: DesignTokens.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.error ?? 'Terjadi kesalahan',
            style: GoogleFonts.poppins(
              color: DesignTokens.textPrimaryDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '',
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primaryColor,
            ),
            child: Text(
              l10n?.retry ?? 'Coba Lagi',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _AddCategoryModal(onCategoryAdded: _loadData);
      },
    );
  }

  Future<void> _deleteCategory(dynamic category) async {
    final l10n = AppLocalizations.of(context);
    final categoryId = category['category_id_232143'] ?? category['id'] ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: DesignTokens.surfaceDark,
          title: Text(
            l10n?.delete ?? 'Hapus',
            style: GoogleFonts.poppins(
              color: DesignTokens.textPrimaryDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            l10n?.confirm_delete_budget ?? 'Yakin ingin menghapus kategori ini?',
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n?.cancel ?? 'Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                l10n?.delete ?? 'Hapus',
                style: const TextStyle(color: DesignTokens.errorColor),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _categoryService.deleteCustomCategory(categoryId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.transaction_deleted_successfully ?? 'Kategori berhasil dihapus'),
            backgroundColor: DesignTokens.primaryColor,
          ),
        );
        await _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: DesignTokens.errorColor,
          ),
        );
      }
    }
  }
}

class _AddCategoryModal extends StatefulWidget {
  final VoidCallback onCategoryAdded;

  const _AddCategoryModal({required this.onCategoryAdded});

  @override
  State<_AddCategoryModal> createState() => _AddCategoryModalState();
}

class _AddCategoryModalState extends State<_AddCategoryModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedType = 'expense';
  String _selectedIcon = 'category';
  String _selectedColor = '#8B5FBF';

  final List<Map<String, dynamic>> _types = [
    {'value': 'expense', 'label': 'Expense'},
    {'value': 'income', 'label': 'Income'},
  ];

  final List<String> _colors = [
    '#8B5FBF', '#4CAF50', '#2196F3', '#FF9800', '#F44336', '#9C27B0'
  ];

  final List<Map<String, dynamic>> _icons = [
    {'value': 'restaurant', 'label': 'Food'},
    {'value': 'directions_car', 'label': 'Transport'},
    {'value': 'shopping_cart', 'label': 'Shopping'},
    {'value': 'movie', 'label': 'Entertainment'},
    {'value': 'receipt', 'label': 'Bills'},
    {'value': 'local_hospital', 'label': 'Health'},
    {'value': 'school', 'label': 'Education'},
    {'value': 'work', 'label': 'Salary'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DesignTokens.textTertiaryDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Tambah Kategori',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textPrimaryDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark),
                decoration: InputDecoration(
                  labelText: l10n?.name ?? 'Nama',
                  labelStyle: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark),
                  filled: true,
                  fillColor: DesignTokens.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                    borderSide: BorderSide(color: DesignTokens.borderDark),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Tipe',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _types.map((type) {
                  final isSelected = _selectedType == type['value'];
                  return ChoiceChip(
                    label: Text(
                      type['label'],
                      style: GoogleFonts.poppins(
                        color: isSelected ? Colors.white : DesignTokens.textSecondaryDark,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = type['value'];
                      });
                    },
                    backgroundColor: DesignTokens.surfaceDark,
                    selectedColor: DesignTokens.primaryColor,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Icon',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _icons.map((icon) {
                  final isSelected = _selectedIcon == icon['value'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIcon = icon['value'];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? DesignTokens.primaryColor.withValues(alpha: 0.15)
                            : DesignTokens.surfaceDark,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                        border: Border.all(
                          color: isSelected ? DesignTokens.primaryColor : DesignTokens.borderDark,
                        ),
                      ),
                      child: Icon(
                        _getIconData(icon['value']),
                        color: isSelected ? DesignTokens.primaryColor : DesignTokens.textSecondaryDark,
                        size: 20,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Warna',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _colors.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                    ),
                  ),
                  child: Text(
                    l10n?.add ?? 'Tambah',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Iconsax.coffee;
      case 'directions_car':
        return Iconsax.car;
      case 'shopping_cart':
        return Iconsax.shopping_cart;
      case 'movie':
        return Iconsax.video;
      case 'receipt':
        return Iconsax.receipt;
      case 'local_hospital':
        return Iconsax.health;
      case 'school':
        return Iconsax.book;
      case 'work':
        return Iconsax.briefcase;
      default:
        return Iconsax.category;
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final categoryService = CategoryCustomizationService();
      await categoryService.createCustomCategory(
        name: _nameController.text,
        type: _selectedType,
        icon: _selectedIcon,
        color: _selectedColor,
      );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onCategoryAdded();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: DesignTokens.errorColor,
        ),
      );
    }
  }
}
