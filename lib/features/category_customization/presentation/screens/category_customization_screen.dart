import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/features/category_customization/presentation/controllers/category_controller.dart';
import 'package:financial_app/models/category_model.dart';
import 'package:financial_app/services/category_customization_service.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';

class CategoryCustomizationScreen extends StatefulWidget {
  const CategoryCustomizationScreen({super.key});
  @override
  State<CategoryCustomizationScreen> createState() => _CategoryCustomizationScreenState();
}

class _CategoryCustomizationScreenState extends State<CategoryCustomizationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<CategoryController>().loadData());
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
                onRefresh: () => context.read<CategoryController>().refresh(),
                child: Consumer<CategoryController>(
                  builder: (_, ctrl, __) {
                    if (ctrl.isLoading)
                      return Center(child: CircularProgressIndicator(color: DesignTokens.primaryColor));
                    if (ctrl.error != null) return _buildErrorState(context, l10n, ctrl);
                    final items = <Object>[];
                    if (ctrl.customCategories.isNotEmpty) {
                      items.add('custom_header');
                      items.add('spacing_12');
                      for (final cat in ctrl.customCategories) items.add(_CategoryListItem(cat, isCustom: true));
                      items.add('spacing_16');
                    }
                    items.add('default_header');
                    items.add('spacing_12');
                    for (final cat in ctrl.defaultCategories) items.add(_CategoryListItem(cat, isCustom: false));
                    return ListView.builder(
                      padding: const EdgeInsets.all(DesignTokens.spacing4),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) {
                        final item = items[i];
                        if (item is String) {
                          if (item == 'custom_header')
                            return Text(
                              'Custom Categories',
                              style: GoogleFonts.poppins(
                                color: DesignTokens.textPrimaryDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          if (item == 'default_header')
                            return Text(
                              'Default Categories',
                              style: GoogleFonts.poppins(
                                color: DesignTokens.textPrimaryDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          if (item == 'spacing_12') return const SizedBox(height: DesignTokens.spacing3);
                          if (item == 'spacing_16') return const SizedBox(height: DesignTokens.spacing4);
                          return const SizedBox.shrink();
                        }
                        final li = item as _CategoryListItem;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildCategoryCard(ctx, li.category, l10n, isCustom: li.isCustom, ctrl: ctrl),
                        );
                      },
                    );
                  },
                ),
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
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Iconsax.arrow_left, color: DesignTokens.textPrimaryDark),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            l10n?.category ?? 'Kategori',
            style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Consumer<CategoryController>(
            builder:
                (_, ctrl, __) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: DesignTokens.surfaceDark,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                    border: Border.all(color: DesignTokens.borderDark),
                  ),
                  child: Text(
                    '${ctrl.defaultCategories.length + ctrl.customCategories.length} ${l10n?.total_categories ?? 'kategori'}',
                    style: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark, fontSize: 12),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    CategoryModel category,
    AppLocalizations? l10n, {
    required bool isCustom,
    required CategoryController ctrl,
  }) {
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
              color: _getCategoryColor(category.color).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            ),
            child: Icon(_getIconData(category.icon), color: _getCategoryColor(category.color), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: GoogleFonts.poppins(
                    color: DesignTokens.textPrimaryDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  category.type == 'income' ? 'Income' : 'Expense',
                  style: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark, fontSize: 11),
                ),
              ],
            ),
          ),
          if (isCustom)
            InkWell(
              onTap: () => _deleteCategory(category, ctrl),
              child: Icon(Iconsax.trash, size: 16, color: DesignTokens.errorColor),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations? l10n, CategoryController ctrl) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2, size: 64, color: DesignTokens.errorColor),
          const SizedBox(height: DesignTokens.spacing4),
          Text(
            l10n?.error ?? 'Terjadi kesalahan',
            style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: DesignTokens.spacing2),
          Text(ctrl.error ?? '', style: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark, fontSize: 14)),
          const SizedBox(height: DesignTokens.spacing4),
          ElevatedButton(
            onPressed: ctrl.refresh,
            style: ElevatedButton.styleFrom(backgroundColor: DesignTokens.primaryColor),
            child: Text(l10n?.retry ?? 'Coba Lagi', style: GoogleFonts.poppins(color: Colors.white)),
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

  void _showAddCategoryModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => _AddCategoryModal(onCategoryAdded: () => context.read<CategoryController>().loadData()),
    );
  }

  Future<void> _deleteCategory(CategoryModel category, CategoryController ctrl) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
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
              l10n?.delete_category_confirm ?? 'Yakin ingin menghapus kategori ini?',
              style: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark, fontSize: 13),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n?.cancel ?? 'Batal')),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text(l10n?.delete ?? 'Hapus', style: const TextStyle(color: DesignTokens.errorColor)),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      try {
        await ctrl.deleteCategory(category);
        if (mounted)
          ErrorHandlerService.showSuccessSnackbar(context, l10n?.category_deleted ?? 'Kategori berhasil dihapus');
      } catch (e) {
        if (mounted) ErrorHandlerService.showErrorSnackbar(context, ErrorHandlerService.getUserFriendlyMessage(e));
      }
    }
  }
}

class _CategoryListItem {
  final CategoryModel category;
  final bool isCustom;
  const _CategoryListItem(this.category, {required this.isCustom});
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
  final List<String> _colors = ['#8B5FBF', '#4CAF50', '#2196F3', '#FF9800', '#F44336', '#9C27B0'];
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
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
              const SizedBox(height: DesignTokens.spacing5),
              Text(
                l10n?.add_category ?? 'Tambah Kategori',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textPrimaryDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: DesignTokens.spacing5),
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
                validator: (v) => (v == null || v.isEmpty) ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: DesignTokens.spacing4),
              Text('Tipe', style: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark, fontSize: 12)),
              const SizedBox(height: DesignTokens.spacing2),
              Wrap(
                spacing: 8,
                children:
                    _types.map((t) {
                      final sel = _selectedType == t['value'];
                      return ChoiceChip(
                        label: Text(
                          t['label'],
                          style: GoogleFonts.poppins(
                            color: sel ? Colors.white : DesignTokens.textSecondaryDark,
                            fontSize: 12,
                          ),
                        ),
                        selected: sel,
                        onSelected: (_) => setState(() => _selectedType = t['value']),
                        backgroundColor: DesignTokens.surfaceDark,
                        selectedColor: DesignTokens.primaryColor,
                      );
                    }).toList(),
              ),
              const SizedBox(height: DesignTokens.spacing4),
              Text('Icon', style: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark, fontSize: 12)),
              const SizedBox(height: DesignTokens.spacing2),
              Wrap(
                spacing: 8,
                children:
                    _icons.map((ic) {
                      final sel = _selectedIcon == ic['value'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = ic['value']),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: sel ? DesignTokens.primaryColor.withValues(alpha: 0.15) : DesignTokens.surfaceDark,
                            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                            border: Border.all(color: sel ? DesignTokens.primaryColor : DesignTokens.borderDark),
                          ),
                          child: Icon(
                            _getIconData(ic['value']),
                            color: sel ? DesignTokens.primaryColor : DesignTokens.textSecondaryDark,
                            size: 20,
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: DesignTokens.spacing4),
              Text('Warna', style: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark, fontSize: 12)),
              const SizedBox(height: DesignTokens.spacing2),
              Wrap(
                spacing: 8,
                children:
                    _colors.map((c) {
                      final sel = _selectedColor == c;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = c),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(int.parse(c.replaceFirst('#', '0xFF'))),
                            shape: BoxShape.circle,
                            border: sel ? Border.all(color: Colors.white, width: 3) : null,
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: DesignTokens.spacing6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMedium)),
                  ),
                  child: Text(
                    l10n?.add ?? 'Tambah',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacing5),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await CategoryCustomizationService().createCustomCategory(
        name: _nameController.text,
        type: _selectedType,
        icon: _selectedIcon,
        color: _selectedColor,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onCategoryAdded();
    } catch (e) {
      if (mounted) ErrorHandlerService.showErrorSnackbar(context, ErrorHandlerService.getUserFriendlyMessage(e));
    }
  }
}
