import 'dart:async';
import 'package:financial_app/services/category_customization_service.dart';
import 'package:financial_app/models/category_model.dart';

/// Category Customization Repository - delegates to CategoryCustomizationService.
class CategoryCustomizationRepository {
  final CategoryCustomizationService _service;

  CategoryCustomizationRepository({CategoryCustomizationService? service})
      : _service = service ?? CategoryCustomizationService();

  Future<List<CategoryModel>> getAllCategoriesWithCustomizations() async {
    return await _service.getAllCategoriesWithCustomizations();
  }

  Future<List<CategoryModel>> getCustomCategories() async {
    return await _service.getCustomCategories();
  }

  Future<void> deleteCustomCategory(String id) async {
    return await _service.deleteCustomCategory(id);
  }
}
