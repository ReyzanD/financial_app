import 'package:flutter/foundation.dart';
import 'package:financial_app/services/category_customization_service.dart';
import 'package:financial_app/services/logger_service.dart';

class CategoryController extends ChangeNotifier {
  final CategoryCustomizationService _s;
  CategoryController({CategoryCustomizationService? service})
    : _s = service ?? CategoryCustomizationService();

  List<dynamic> _defaultCategories = [];
  List<dynamic> _customCategories = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get defaultCategories => _defaultCategories;
  List<dynamic> get customCategories => _customCategories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _s.getAllCategoriesWithCustomizations(),
        _s.getCustomCategories(),
      ]);
      final allCategories = results[0] as List<dynamic>;
      _customCategories = results[1] as List<dynamic>;
      _defaultCategories =
          allCategories
              .where(
                (c) =>
                    (c['is_system_default_232143'] ??
                        c['is_system_default'] ??
                        0) ==
                    1,
              )
              .toList();
    } catch (e) {
      LoggerService.error('Error loading categories', error: e);
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCategory(dynamic category) async {
    final categoryId = category['category_id_232143'] ?? category['id'] ?? '';
    try {
      await _s.deleteCustomCategory(categoryId);
      await loadData();
    } catch (e) {
      LoggerService.error('Error deleting category', error: e);
      rethrow;
    }
  }

  Future<void> refresh() async => loadData();
}
