import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/features/budgets/presentation/controllers/budget_controller.dart';
import 'package:financial_app/features/budgets/domain/use_cases/get_budgets_use_case.dart';
import 'package:financial_app/features/budgets/domain/use_cases/create_budget_use_case.dart';
import 'package:financial_app/features/budgets/domain/use_cases/delete_budget_use_case.dart';
import 'package:financial_app/features/budgets/domain/use_cases/update_budget_use_case.dart';
import 'package:financial_app/features/budgets/data/repositories/budget_repository.dart';

void main() {
  group('BudgetController summary getter', () {
    late BudgetController controller;
    late GetBudgetsUseCase getBudgetsUseCase;
    late CreateBudgetUseCase createBudgetUseCase;
    late DeleteBudgetUseCase deleteBudgetUseCase;
    late UpdateBudgetUseCase updateBudgetUseCase;
    late BudgetRepository repository;

    setUp(() {
      // Use mock-like empty implementations since we're testing the getter, not data loading
      getBudgetsUseCase = GetBudgetsUseCase(BudgetRepository());
      createBudgetUseCase = CreateBudgetUseCase(BudgetRepository());
      deleteBudgetUseCase = DeleteBudgetUseCase(BudgetRepository());
      updateBudgetUseCase = UpdateBudgetUseCase(BudgetRepository());
      repository = BudgetRepository();

      controller = BudgetController(
        getBudgetsUseCase,
        createBudgetUseCase,
        deleteBudgetUseCase,
        updateBudgetUseCase,
        repository,
      );
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
