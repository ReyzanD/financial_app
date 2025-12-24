# Code Style Guide

## File Headers

All Dart files should start with a documentation header:

```dart
/// Brief description of the file
///
/// Detailed description explaining what this file does, its purpose,
/// and any important implementation details.
///
/// Features:
/// - Feature 1
/// - Feature 2
///
/// Usage:
/// ```dart
/// // Example usage code
/// ```
///
/// Author: Financial App Team
/// Last Updated: 2024
```

## Class Documentation

All public classes should have documentation:

```dart
/// Brief description of the class
///
/// Detailed explanation of the class purpose, responsibilities,
/// and how it fits into the overall architecture.
///
/// Example:
/// ```dart
/// final service = MyService();
/// await service.doSomething();
/// ```
class MyService {
  // ...
}
```

## Method Documentation

All public methods should have documentation:

```dart
/// Brief description of what the method does
///
/// [param1] Description of parameter 1
/// [param2] Description of parameter 2
/// 
/// Returns: Description of return value
/// 
/// Throws: [ExceptionType] When this exception is thrown
/// 
/// Example:
/// ```dart
/// final result = await method(param1, param2);
/// ```
Future<String> method(String param1, int param2) async {
  // ...
}
```

## Naming Conventions

### Files
- Use snake_case: `transaction_service.dart`
- Screen files: `{feature}_screen.dart`
- Widget files: `{feature}_widget.dart`
- Service files: `{feature}_service.dart`

### Classes
- Use PascalCase: `TransactionService`
- Widget classes: `TransactionCard`
- Service classes: `TransactionService`

### Variables and Methods
- Use camelCase: `transactionAmount`, `getTransactions()`
- Private members: `_privateField`, `_privateMethod()`
- Constants: `CONSTANT_VALUE` or `kConstantValue`

### Boolean Variables
- Use positive names: `isLoading`, `hasData`, `canEdit`
- Avoid negatives: `isNotLoading`, `hasNoData`

## Code Organization

### Import Order
1. Dart SDK imports
2. Flutter imports
3. Package imports
4. Local imports (relative)

```dart
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction_model.dart';
import '../services/api_service.dart';
```

### Class Structure
1. Constants
2. Static fields
3. Instance fields
4. Constructors
5. Getters/Setters
6. Public methods
7. Private methods

## Widget Guidelines

### Use const constructors when possible
```dart
const TransactionCard({
  required this.transaction,
  super.key,
});
```

### Extract complex widgets
If a widget method exceeds 50 lines, extract it to a separate widget.

### Use meaningful widget names
```dart
// Good
Widget _buildTransactionHeader() { }

// Bad
Widget _buildHeader() { }
```

## Error Handling

### Use ErrorHandlerService for user-facing errors
```dart
try {
  await apiService.getData();
} catch (e) {
  ErrorHandlerService.showErrorSnackbar(
    context,
    ErrorHandlerService.getUserFriendlyMessage(e),
    onRetry: () => _loadData(),
  );
}
```

### Use LoggerService for debugging
```dart
LoggerService.debug('Loading data...');
LoggerService.error('Error occurred', error: e);
```

## State Management

### Use Provider for state management
```dart
Consumer<AppState>(
  builder: (context, appState, child) {
    return Text('${appState.transactions.length}');
  },
)
```

### Use Selector for selective rebuilds
```dart
Selector<AppState, int>(
  selector: (_, state) => state.transactions.length,
  builder: (context, count, child) {
    return Text('$count');
  },
)
```

## Testing

### Unit Tests
- Test business logic in services and use cases
- Mock dependencies
- Test edge cases and error conditions

### Widget Tests
- Test widget rendering
- Test user interactions
- Test state changes

### Integration Tests
- Test complete user flows
- Test API integration
- Test navigation

## Performance

### Use const widgets
```dart
const SizedBox(height: 16)
```

### Avoid unnecessary rebuilds
- Use `const` constructors
- Use `Selector` instead of `Consumer` when possible
- Extract widgets that don't need to rebuild

### Optimize lists
- Use `ListView.builder` for long lists
- Implement pagination for large datasets
- Use `cacheExtent` for better performance

## Security

### Never log sensitive data
```dart
// Bad
LoggerService.debug('Password: $password');

// Good
LoggerService.debug('User authenticated');
```

### Validate all inputs
```dart
final amount = FormValidators.validateAmount(amountText);
if (amount != null) {
  // Handle error
}
```

### Use secure storage for sensitive data
```dart
final storage = FlutterSecureStorage();
await storage.write(key: 'token', value: token);
```

