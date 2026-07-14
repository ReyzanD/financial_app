import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/features/budgets/presentation/controllers/budget_controller.dart';
import 'package:financial_app/features/budgets/data/repositories/budget_repository.dart';
import 'package:financial_app/services/data/budget_data_service.dart';
import 'package:financial_app/services/data/category_data_service.dart';

void main() {
  group('BudgetController summary getter', () {
    late BudgetController controller;
    late BudgetRepository repository;

    setUp(() {
      final catData = CategoryDataService();
      final budgetData = BudgetDataService();
      repository = BudgetRepository(categoryData: catData, budgetData: budgetData);
      controller = BudgetController(repository);
    });

    test('should return empty map when _summary is null', () {
      // _summary is initially null
      final result = controller.summary;
      expect(result, isA<Map<String, dynamic>>());
      expect(result, isEmpty);
    });

    test('should not throw when accessing summary fields on null state', () {
      // Accessing fields on empty summary should not throw
      final summary = controller.summary;
      expect(summary['total_budget'], null);
      expect(summary['total_spent'], null);
      expect(summary['remaining'], null);
    });
  });
}
