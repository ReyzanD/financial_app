import 'base_api.dart';

/// API client for category-related endpoints
class CategoryApi {
  /// Get all categories
  static Future<List<dynamic>> getCategories() async {
    final response = await BaseApiClient.get('categories_232143');
    return response['categories'] ?? [];
  }

  /// Get single category by ID
  static Future<Map<String, dynamic>> getCategory(String id) async {
    final response = await BaseApiClient.get('categories_232143/$id');
    return response['category'] ?? {};
  }

  /// Create new category
  static Future<Map<String, dynamic>> createCategory(
    Map<String, dynamic> categoryData,
  ) async {
    return await BaseApiClient.post('categories_232143', categoryData);
  }

  /// Update category
  static Future<Map<String, dynamic>> updateCategory(
    String id,
    Map<String, dynamic> categoryData,
  ) async {
    return await BaseApiClient.put('categories_232143/$id', categoryData);
  }

  /// Delete category
  static Future<Map<String, dynamic>> deleteCategory(String id) async {
    return await BaseApiClient.delete('categories_232143/$id');
  }
}
