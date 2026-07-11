import 'package:uuid/uuid.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/logger_service.dart';

/// Data service for Category CRUD operations.
/// Extracted from the monolithic LocalDataService facade.
class CategoryDataService {
  final LocalDatabaseService _dbService;
  final LocalAuthService _authService;
  final _uuid = const Uuid();

  CategoryDataService({
    LocalDatabaseService? dbService,
    LocalAuthService? authService,
  }) : _dbService = dbService ?? LocalDatabaseService(),
       _authService = authService ?? LocalAuthService();

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    return await _authService.getCurrentUserId();
  }

  /// Get categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final categories = await db.query(
        'categories_232143',
        where: 'user_id_232143 = ?',
        whereArgs: [userId],
        orderBy: 'type_232143, display_order_232143',
      );

      return List<Map<String, dynamic>>.from(categories);
    } catch (e) {
      LoggerService.error('Error getting categories', error: e);
      rethrow;
    }
  }

  /// Add category
  Future<Map<String, dynamic>> addCategory(
    Map<String, dynamic> categoryData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final categoryId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final data = {
        'category_id_232143': categoryId,
        'user_id_232143': userId,
        'name_232143': categoryData['name'],
        'type_232143': categoryData['type'],
        'color_232143': categoryData['color'] ?? '#3498db',
        'icon_232143': categoryData['icon'] ?? 'receipt',
        'budget_limit_232143': categoryData['budget_limit'],
        'budget_period_232143': categoryData['budget_period'] ?? 'monthly',
        'display_order_232143': categoryData['display_order'] ?? 0,
        'created_at_232143': now,
        'updated_at_232143': now,
      };

      await db.insert('categories_232143', data);
      LoggerService.info('✅ Category added: $categoryId');
      return {'category': data};
    } catch (e) {
      LoggerService.error('Error adding category', error: e);
      rethrow;
    }
  }

  /// Update category
  Future<Map<String, dynamic>> updateCategory(
    String id,
    Map<String, dynamic> categoryData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final now = DateTime.now().toIso8601String();

      final updateData = <String, dynamic>{'updated_at_232143': now};

      if (categoryData.containsKey('name')) {
        updateData['name_232143'] = categoryData['name'];
      }
      if (categoryData.containsKey('color')) {
        updateData['color_232143'] = categoryData['color'];
      }
      if (categoryData.containsKey('icon')) {
        updateData['icon_232143'] = categoryData['icon'];
      }
      if (categoryData.containsKey('budget_limit')) {
        updateData['budget_limit_232143'] = categoryData['budget_limit'];
      }

      await db.update(
        'categories_232143',
        updateData,
        where: 'category_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [id, userId],
      );

      final categories = await db.query(
        'categories_232143',
        where: 'category_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [id, userId],
      );

      return {'category': categories.first};
    } catch (e) {
      LoggerService.error('Error updating category', error: e);
      rethrow;
    }
  }

  /// Delete category
  Future<void> deleteCategory(String id) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      await db.delete(
        'categories_232143',
        where: 'category_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [id, userId],
      );

      LoggerService.info('✅ Category deleted: $id');
    } catch (e) {
      LoggerService.error('Error deleting category', error: e);
      rethrow;
    }
  }
}
