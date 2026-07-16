import 'package:financial_app/models/category_model.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/data/category_data_service.dart';

class CategoryCustomizationService {
  final CategoryDataService _categoryData;

  CategoryCustomizationService({CategoryDataService? categoryData})
    : _categoryData = categoryData ?? getIt<CategoryDataService>();

  Future<List<CategoryModel>> getCustomCategories() async {
    final categories = await _categoryData.getCategories();
    return categories.where((c) => c.isSystemDefault == false).toList();
  }

  Future<CategoryModel> createCustomCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
    String? parentId,
  }) async {
    final categoryData = {
      'name': name,
      'type': type,
      'icon': icon ?? 'category',
      'color': color ?? '#8B5FBF',
      'budget_period': 'monthly',
      'display_order': 0,
    };

    return await _categoryData.addCategory(categoryData);
  }

  Future<CategoryModel> updateCustomCategory(String categoryId, Map<String, dynamic> updates) async {
    return await _categoryData.updateCategory(categoryId, updates);
  }

  Future<void> deleteCustomCategory(String categoryId) async {
    await _categoryData.deleteCategory(categoryId);
  }

  Future<String> getCategoryIcon(String categoryId) async {
    final categories = await _categoryData.getCategories();
    for (final c in categories) {
      if (c.id == categoryId) return c.icon;
    }
    return 'category';
  }

  Future<void> setCategoryIcon(String categoryId, String icon) async {
    await _categoryData.updateCategory(categoryId, {'icon': icon});
  }

  Future<String> getCategoryColor(String categoryId) async {
    final categories = await _categoryData.getCategories();
    for (final c in categories) {
      if (c.id == categoryId) return c.color;
    }
    return '#8B5FBF';
  }

  Future<void> setCategoryColor(String categoryId, String color) async {
    await _categoryData.updateCategory(categoryId, {'color': color});
  }

  Future<List<CategoryModel>> getAllCategoriesWithCustomizations() async {
    return await _categoryData.getCategories();
  }

  static List<Map<String, dynamic>> getDefaultCategories() {
    return [
      {'id': 'food', 'name': 'Makanan', 'icon': 'restaurant', 'color': '#FF5722', 'type': 'expense'},
      {'id': 'transport', 'name': 'Transportasi', 'icon': 'directions_car', 'color': '#2196F3', 'type': 'expense'},
      {'id': 'shopping', 'name': 'Belanja', 'icon': 'shopping_cart', 'color': '#9C27B0', 'type': 'expense'},
      {'id': 'entertainment', 'name': 'Hiburan', 'icon': 'movie', 'color': '#FF9800', 'type': 'expense'},
      {'id': 'bills', 'name': 'Tagihan', 'icon': 'receipt', 'color': '#607D8B', 'type': 'expense'},
      {'id': 'health', 'name': 'Kesehatan', 'icon': 'local_hospital', 'color': '#4CAF50', 'type': 'expense'},
      {'id': 'education', 'name': 'Pendidikan', 'icon': 'school', 'color': '#3F51B5', 'type': 'expense'},
      {'id': 'salary', 'name': 'Gaji', 'icon': 'work', 'color': '#4CAF50', 'type': 'income'},
      {'id': 'freelance', 'name': 'Freelance', 'icon': 'laptop', 'color': '#00BCD4', 'type': 'income'},
      {'id': 'investment', 'name': 'Investasi', 'icon': 'trending_up', 'color': '#8BC34A', 'type': 'income'},
    ];
  }

  static List<String> getAvailableIcons() {
    return [
      'restaurant',
      'directions_car',
      'shopping_cart',
      'movie',
      'receipt',
      'local_hospital',
      'school',
      'work',
      'laptop',
      'trending_up',
      'home',
      'flight',
      'pets',
      'fitness_center',
      'coffee',
      'phone_android',
      'gamepad',
      'music_note',
      'favorite',
      'star',
      'category',
      'wallet',
      'account_balance',
      'payments',
      'savings',
    ];
  }
}
