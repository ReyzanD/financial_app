import 'package:flutter/foundation.dart';
import 'package:financial_app/models/category_model.dart';
import 'package:financial_app/features/category_customization/data/repositories/category_customization_repository.dart';

class CategoryController extends ChangeNotifier {
  final CategoryCustomizationRepository _repository;
  CategoryController({CategoryCustomizationRepository? repository})
      : _repository = repository ?? CategoryCustomizationRepository();

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
        _repository.getAllCategoriesWithCustomizations(),
        _repository.getCustomCategories(),
      ]);
      final allCategories = results[0];
      _customCategories = results[1];
      _defaultCategories = allCategories.where((c) => c.isSystemDefault).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCategory(CategoryModel category) async {
    try {
      await _repository.deleteCustomCategory(category.id);
      await loadData();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async => loadData();
}
