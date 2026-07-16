import 'package:flutter/foundation.dart';
import 'package:financial_app/services/category_customization_service.dart';
import 'package:financial_app/models/category_model.dart';

class CategoryController extends ChangeNotifier {
  final CategoryCustomizationService _s;
  CategoryController({CategoryCustomizationService? service})
    : _s = service ?? CategoryCustomizationService();

  List<CategoryModel> _defaultCategories = [];
  List<CategoryModel> _customCategories = [];
  bool _isLoading = false;
  String? _error;

  List<CategoryModel> get defaultCategories => _defaultCategories;
  List<CategoryModel> get customCategories => _customCategories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait<List<CategoryModel>>([
        _s.getAllCategoriesWithCustomizations(),
        _s.getCustomCategories(),
      ]);
      final allCategories = results[0];
      _customCategories = results[1];
      _defaultCategories =
          allCategories.where((c) => c.isSystemDefault).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCategory(CategoryModel category) async {
    try {
      await _s.deleteCustomCategory(category.id);
      await loadData();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async => loadData();
}
