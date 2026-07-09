import 'package:financial_app/services/local_data_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/core/di/service_locator.dart';

class CategoryCustomizationService {
  final LocalDataService _localData = getIt<LocalDataService>();

  Future<List<Map<String, dynamic>>> getCustomCategories() async {
    try {
      final categories = await _localData.getCategories();
      return categories
          .where(
            (c) =>
                (c['is_system_default_232143'] as int? ??
                    c['is_system_default'] as int? ??
                    0) ==
                0,
          )
          .toList();
    } catch (e) {
      LoggerService.error('Error getting custom categories', error: e);
      return [];
    }
  }

  Future<Map<String, dynamic>> createCustomCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
    String? parentId,
  }) async {
    try {
      final categoryData = {
        'name': name,
        'type': type,
        'icon': icon ?? 'category',
        'color': color ?? '#8B5FBF',
        'budget_period': 'monthly',
        'display_order': 0,
      };

      final result = await _localData.addCategory(categoryData);
      LoggerService.success('Custom category created: $name');
      return result['category'] as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('Error creating custom category', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateCustomCategory(
    String categoryId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final result = await _localData.updateCategory(categoryId, updates);
      return result['category'] as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('Error updating custom category', error: e);
      rethrow;
    }
  }

  Future<void> deleteCustomCategory(String categoryId) async {
    try {
      await _localData.deleteCategory(categoryId);
      LoggerService.success('Custom category deleted');
    } catch (e) {
      LoggerService.error('Error deleting custom category', error: e);
      rethrow;
    }
  }

  Future<String> getCategoryIcon(String categoryId) async {
    try {
      final categories = await _localData.getCategories();
      final category = categories.firstWhere(
        (c) => (c['category_id_232143'] ?? c['id']) == categoryId,
        orElse: () => {},
      );
      return (category['icon_232143'] ?? category['icon'])?.toString() ??
          'category';
    } catch (e) {
      return 'category';
    }
  }

  Future<void> setCategoryIcon(String categoryId, String icon) async {
    try {
      await _localData.updateCategory(categoryId, {'icon': icon});
    } catch (e) {
      LoggerService.error('Error setting category icon', error: e);
    }
  }

  Future<String> getCategoryColor(String categoryId) async {
    try {
      final categories = await _localData.getCategories();
      final category = categories.firstWhere(
        (c) => (c['category_id_232143'] ?? c['id']) == categoryId,
        orElse: () => {},
      );
      return (category['color_232143'] ?? category['color'])?.toString() ??
          '#8B5FBF';
    } catch (e) {
      return '#8B5FBF';
    }
  }

  Future<void> setCategoryColor(String categoryId, String color) async {
    try {
      await _localData.updateCategory(categoryId, {'color': color});
    } catch (e) {
      LoggerService.error('Error setting category color', error: e);
    }
  }

  Future<List<Map<String, dynamic>>>
  getAllCategoriesWithCustomizations() async {
    return await _localData.getCategories();
  }

  static List<Map<String, dynamic>> getDefaultCategories() {
    return [
      {
        'id': 'food',
        'name': 'Makanan',
        'icon': 'restaurant',
        'color': '#FF5722',
        'type': 'expense',
      },
      {
        'id': 'transport',
        'name': 'Transportasi',
        'icon': 'directions_car',
        'color': '#2196F3',
        'type': 'expense',
      },
      {
        'id': 'shopping',
        'name': 'Belanja',
        'icon': 'shopping_cart',
        'color': '#9C27B0',
        'type': 'expense',
      },
      {
        'id': 'entertainment',
        'name': 'Hiburan',
        'icon': 'movie',
        'color': '#FF9800',
        'type': 'expense',
      },
      {
        'id': 'bills',
        'name': 'Tagihan',
        'icon': 'receipt',
        'color': '#607D8B',
        'type': 'expense',
      },
      {
        'id': 'health',
        'name': 'Kesehatan',
        'icon': 'local_hospital',
        'color': '#4CAF50',
        'type': 'expense',
      },
      {
        'id': 'education',
        'name': 'Pendidikan',
        'icon': 'school',
        'color': '#3F51B5',
        'type': 'expense',
      },
      {
        'id': 'salary',
        'name': 'Gaji',
        'icon': 'work',
        'color': '#4CAF50',
        'type': 'income',
      },
      {
        'id': 'freelance',
        'name': 'Freelance',
        'icon': 'laptop',
        'color': '#00BCD4',
        'type': 'income',
      },
      {
        'id': 'investment',
        'name': 'Investasi',
        'icon': 'trending_up',
        'color': '#8BC34A',
        'type': 'income',
      },
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
