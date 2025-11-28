# Code Refactoring Guide

## Files That Need Refactoring (Priority Order)

### 🔴 Critical (>800 lines)
1. **ai_budget_recommendation_screen.dart** (992 lines)
   - Extract budget category cards into separate widgets
   - Extract recommendation logic into service
   - Create `widgets/budget_recommendation/` folder with:
     - `budget_category_card.dart`
     - `budget_edit_dialog.dart`
     - `budget_apply_button.dart`

2. **quick_add_widget.dart** (967 lines)
   - ✅ STARTED: Created `quick_add/quick_amount_selector.dart`
   - ✅ STARTED: Created `quick_add/quick_category_selector.dart`
   - TODO: Create `quick_add_modal.dart` (separate from main widget)
   - TODO: Extract `_QuickAddModalState` to standalone file

### 🟡 Medium (600-800 lines)
3. **api_service.dart** (683 lines)
   - Split into multiple service files:
     - `api/transaction_api.dart`
     - `api/budget_api.dart`
     - `api/goal_api.dart`
     - `api/obligation_api.dart`
     - `api/category_api.dart`

4. **add_transaction_screen.dart** (663 lines)
   - Already well-organized with extracted widgets
   - Consider extracting `_AddTransactionScreenState` logic into controller

### 🟢 Lower Priority (400-600 lines)
5. **add_obligation_modal.dart** (513 lines)
   - Extract form fields into separate widgets
   - Create `obligation_forms/` folder

6. **financial_summary_card.dart** (413 lines)
   - Extract summary items into separate widget
   - Separate animation logic

## Refactoring Patterns to Follow

### 1. Widget Extraction
```dart
// Before: Large widget with 500+ lines
class LargeWidget extends StatefulWidget { ... }

// After: Split into multiple small widgets
class LargeWidget extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HeaderSection(),
        ContentSection(),
        FooterSection(),
      ],
    );
  }
}
```

### 2. Service Layer Separation
```dart
// Before: All API calls in one file
class ApiService {
  Future<void> getTransactions() { ... }
  Future<void> getBudgets() { ... }
  Future<void> getGoals() { ... }
}

// After: Split by domain
class TransactionApiService { ... }
class BudgetApiService { ... }
class GoalApiService { ... }
```

### 3. Logic Extraction
```dart
// Before: Business logic in widget
class MyWidget extends StatefulWidget {
  void _complexCalculation() {
    // 100 lines of logic
  }
}

// After: Logic in separate class
class MyCalculator {
  static double calculate() { ... }
}
```

## Benefits of Refactoring

### ✅ Improved
- **Maintainability**: Easier to find and fix bugs
- **Readability**: Each file has single responsibility
- **Testability**: Smaller units easier to test
- **Reusability**: Components can be reused
- **Performance**: Smaller widgets rebuild faster

### 📊 Target Metrics
- Max file size: **300 lines**
- Max widget size: **150 lines**
- Max function size: **50 lines**

## Implementation Strategy

1. **Phase 1** (Completed):
   - Created `quick_amount_selector.dart`
   - Created `quick_category_selector.dart`

2. **Phase 2** (Next):
   - Refactor `ai_budget_recommendation_screen.dart`
   - Split `api_service.dart`

3. **Phase 3** (Future):
   - Refactor remaining large files
   - Add unit tests for extracted components
   - Document component usage

## Notes
- Always maintain backward compatibility
- Test after each refactoring
- Update imports in dependent files
- Keep related files in same folder
