# Architecture Migration Guide

## Current State

### Feature-Based Structure (Clean Architecture)
The following features already follow clean architecture:

- ✅ **Transactions** (`lib/features/transactions/`)
  - Data layer with repositories and datasources
  - Domain layer with entities and use cases
  - Presentation layer with controllers

- ✅ **Budgets** (`lib/features/budgets/`)
  - Data layer with repositories
  - Domain layer with entities
  - Repository interfaces

- ✅ **Home** (`lib/features/home/`)
  - Presentation controllers

### Traditional Structure
The following screens are still in traditional structure (`lib/Screen/`):

- `add_transaction_screen.dart` - Can migrate to `features/transactions/presentation/screens/`
- `transaction_history_screen.dart` - Can migrate to `features/transactions/presentation/screens/`
- `transaction_screen.dart` - Can migrate to `features/transactions/presentation/screens/`
- `budgets_screen.dart` - Can migrate to `features/budgets/presentation/screens/`
- `goals_screen.dart` - Can create `features/goals/`
- `analytics_screen.dart` - Can create `features/analytics/`
- `settings_screen.dart` - Can create `features/settings/`
- `profile_screen.dart` - Can create `features/profile/`

## Migration Strategy

### Step 1: Create Feature Structure
For each feature, create the following structure:
```
lib/features/{feature_name}/
  ├── data/
  │   ├── datasources/
  │   │   └── {feature}_remote_datasource.dart
  │   └── repositories/
  │       └── {feature}_repository.dart
  ├── domain/
  │   ├── entities/
  │   │   └── {feature}_entity.dart
  │   ├── repositories/
  │   │   └── {feature}_repository_interface.dart
  │   └── use_cases/
  │       ├── get_{feature}s_use_case.dart
  │       ├── create_{feature}_use_case.dart
  │       └── update_{feature}_use_case.dart
  └── presentation/
      ├── controllers/
      │   └── {feature}_controller.dart
      ├── screens/
      │   └── {feature}_screen.dart
      └── widgets/
          └── {feature}_widget.dart
```

### Step 2: Extract Business Logic
Move business logic from screens to:
- **Use Cases**: Business rules and operations
- **Controllers**: State management and UI logic
- **Repositories**: Data access abstraction

### Step 3: Update Dependencies
- Use dependency injection (GetIt) for all dependencies
- Replace direct service calls with repository interfaces
- Use use cases instead of direct API calls

### Step 4: Update Navigation
Update route definitions to point to new screen locations.

## Example: Migrating Goals Screen

### Before (Traditional)
```dart
// lib/Screen/goals_screen.dart
class GoalsScreen extends StatefulWidget {
  final ApiService _apiService = ApiService();
  
  Future<void> _loadGoals() async {
    final goals = await _apiService.getGoals();
    // ...
  }
}
```

### After (Clean Architecture)
```dart
// lib/features/goals/domain/entities/goal_entity.dart
class GoalEntity {
  final String id;
  final String name;
  final double targetAmount;
  // ...
}

// lib/features/goals/domain/use_cases/get_goals_use_case.dart
class GetGoalsUseCase {
  final GoalRepositoryInterface repository;
  
  Future<List<GoalEntity>> call() async {
    return await repository.getGoals();
  }
}

// lib/features/goals/presentation/controllers/goal_controller.dart
class GoalController extends ChangeNotifier {
  final GetGoalsUseCase getGoalsUseCase;
  
  Future<void> loadGoals() async {
    _goals = await getGoalsUseCase();
    notifyListeners();
  }
}

// lib/features/goals/presentation/screens/goals_screen.dart
class GoalsScreen extends StatelessWidget {
  final GoalController controller;
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => controller,
      child: Consumer<GoalController>(
        builder: (context, controller, _) {
          // UI code
        },
      ),
    );
  }
}
```

## Benefits of Migration

1. **Separation of Concerns**: Business logic separated from UI
2. **Testability**: Easy to unit test use cases and repositories
3. **Maintainability**: Clear structure and dependencies
4. **Reusability**: Use cases can be reused across different UIs
5. **Scalability**: Easy to add new features following the same pattern

## Migration Priority

1. **High Priority**: Features with complex business logic
   - Transactions (partially done)
   - Budgets (partially done)
   - Goals

2. **Medium Priority**: Features with moderate complexity
   - Analytics
   - Reports
   - Settings

3. **Low Priority**: Simple screens
   - Profile
   - Onboarding
   - Authentication screens

## Notes

- Migration can be done incrementally
- Keep old screens until new ones are fully tested
- Use feature flags to switch between old and new implementations
- Update tests as you migrate

