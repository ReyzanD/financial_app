# AGENTS.md - Financial App Development Guide

**Purpose**: This document provides essential information for AI agents working on the Financial App codebase. Follow these guidelines to ensure consistent, maintainable contributions.

---

## Project Overview

**Type**: Flutter mobile application (cross-platform: Android, iOS, Web)
**Language**: Dart (SDK ^3.7.0)
**Architecture**: MVVM with Clean Architecture principles for features
**State Management**: Provider
**Database**: SQLite (local, standalone - no backend server required)
**Primary Language**: Bahasa Indonesia (with English support via l10n)

### Key Characteristics
- **Standalone App**: Runs fully offline with local SQLite database - no backend server needed
- **Financial Application**: Handles transactions, budgets, goals, analytics, obligations
- **Multi-language**: Supports Indonesian and English via ARB files
- **Security-focused**: Encrypted storage, biometric auth, PIN protection
- **Offline-first**: All data stored locally, optional cloud sync capabilities

---

## Essential Commands

### Development
```bash
# Install dependencies
flutter pub get

# Run app (debug mode)
flutter run

# Run on specific device
flutter run -d chrome        # Web
flutter run -d windows       # Windows
flutter run -d <device-id>   # Specific Android/iOS device

# Hot reload (while app is running)
press 'r' in terminal
```

### Building
```bash
# Build APK for Android
flutter build apk --release

# Build app bundle for Play Store
flutter build appbundle --release

# Build for iOS
flutter build ios --release

# Build for Web
flutter build web --release

# Build with obfuscation (recommended for production)
flutter build apk --release --obfuscate --split-debug-info=./debug-info
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/error_handler_service_test.dart

# Run tests with coverage
flutter test --coverage

# Run with platform integration
flutter test --integration
```

### Analysis & Linting
```bash
# Analyze code for issues
flutter analyze

# Fix auto-fixable issues
dart fix --apply

# Format code
dart format .
```

### Dependencies
```bash
# Check for outdated packages
flutter pub outdated

# Upgrade dependencies (major versions)
flutter pub upgrade --major-versions

# Upgrade dependencies (minor/patch)
flutter pub upgrade
```

### Localization
```bash
# Generate localizations from ARB files
flutter gen-l10n
```

---

## Code Organization

### Directory Structure
```
lib/
├── core/              # Core application configurations
│   ├── di/           # Dependency injection (get_it service locator)
│   └── app_config.dart
├── features/         # Clean Architecture feature modules
│   ├── budgets/      # Budget management
│   ├── home/        # Home screen feature
│   └── transactions/ # Transaction management
│       ├── data/    # Data sources & repositories
│       ├── domain/  # Entities, use cases, repository interfaces
│       └── presentation/ # Screens, controllers
├── models/          # Data models (DTOs)
├── services/        # Business logic services
├── widgets/         # Reusable UI components
│   ├── common/     # Generic widgets
│   ├── home/       # Home-specific widgets
│   ├── transactions/
│   └── ...
├── utils/           # Helper utilities
├── state/           # Global state management
├── l10n/            # Localization files
# (legacy Screen/ directory fully migrated to features/ — removed)
```

### File Naming Conventions
- **Screens**: `*_screen.dart` (e.g., `home_screen.dart`)
- **Widgets**: `*_widget.dart` or descriptive name (e.g., `transaction_card.dart`)
- **Services**: `*_service.dart` (e.g., `api_service.dart`)
- **Models**: `*_model.dart` (e.g., `transaction_model.dart`)
- **Utils**: `*.dart` (e.g., `formatters.dart`)
- **Feature files**: Follow clean architecture structure

---

## Architecture & Patterns

### Clean Architecture (for features)
Features use clean architecture with three layers:

1. **Domain Layer** (`features/*/domain/`)
   - Entities: Core business objects (e.g., `TransactionEntity`)
   - Use Cases: Application-specific business rules (e.g., `CreateTransactionUseCase`)
   - Repository Interfaces: Abstract contracts (e.g., `TransactionRepositoryInterface`)

2. **Data Layer** (`features/*/data/`)
   - Data Sources: Where data comes from (e.g., `TransactionRemoteDataSource`)
   - Repositories: Implement repository interfaces (e.g., `TransactionRepository`)
   - DTOs: Data transfer objects for API/database

3. **Presentation Layer** (`features/*/presentation/`)
   - Screens: UI screens
   - Controllers/ViewModels: State management for the feature

### Service Layer
Business logic is encapsulated in services under `lib/services/`:
- Services handle single responsibilities (e.g., `AuthService`, `NotificationService`)
- Use dependency injection via `get_it` (defined in `lib/core/di/service_locator.dart`)
- Services can be accessed via `getIt<ServiceType>()`

### Legacy vs New Code
- **Legacy**: Files directly under `lib/widgets/` using direct Provider access (former `lib/Screen/` content migrated to `lib/features/`)
- **New**: Features in `lib/features/` using clean architecture
- **Transition**: Gradually migrating legacy code to clean architecture

---

## State Management

### Provider Usage
The app uses Provider for global state management:

```dart
// Access provider
final appState = Provider.of<AppState>(context);
final appState = context.watch<AppState>();  // Rebuild on changes
final appState = context.read<AppState>();    // No rebuild

// Update state
appState.someMethod();  // Provider handles notifyListeners() automatically
```

### AppState (`lib/state/app_state.dart`)
Global state manager that:
- Manages transactions, categories, financial summary
- Subscribes to data streams from `DataService`
- Loads initial data on startup
- Handles loading/error states

### Service Locator (get_it)
Dependency injection setup in `lib/core/di/service_locator.dart`:

```dart
// Register service (in setupServiceLocator)
getIt.registerLazySingleton<ApiService>(() => ApiService());

// Access service anywhere
final apiService = getIt<ApiService>();
```

### Common State Patterns
```dart
// Loading state
bool isLoading = false;

// Error handling
String? errorMessage;

// Refresh data
Future<void> refreshData() async {
  setState(() => isLoading = true);
  try {
    // Fetch data
  } catch (e) {
    setState(() => errorMessage = e.toString());
  } finally {
    setState(() => isLoading = false);
  }
}
```

---

## Services Structure

### Core Services
- **LoggerService**: Centralized logging (auto-disabled in release)
- **ErrorHandlerService**: User-friendly error messages in Indonesian
- **NetworkService**: Connectivity monitoring
- **LocalDatabaseService**: SQLite database operations

### Business Services
- **AuthService**: Authentication (PIN, biometric)
- **DataService**: Data fetching and caching
- **NotificationService**: Push notifications
- **AnalyticsService**: Financial analytics
- **BudgetRecommendationService**: AI budget recommendations
- **TransactionService**: Transaction CRUD operations
- **ObligationService**: Bills and subscriptions management
- **LocationService**: Location-based features
- And 30+ more specialized services

### Service Best Practices
1. Use `get_it` for dependency injection
2. Services should be singletons (use `registerLazySingleton`)
3. Services must handle their own errors and return user-friendly messages
4. Use `LoggerService` for logging, never `print()`
5. Initialize services in `main.dart` or service locator setup

---

## Widget Conventions

### Widget Structure
```dart
class MyWidget extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const MyWidget({
    super.key,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Widget content
    );
  }
}
```

### Material Design
- Use `MaterialApp` for app structure
- Follow Material Design 3 guidelines
- Use `Scaffold` for screens with app bars
- Implement proper navigation

### Localization
Always use `AppLocalizations` for user-facing text:

```dart
final l10n = AppLocalizations.of(context);
Text(l10n?.transactions_title ?? 'Transactions');
```

### Common Widgets
The app has reusable widgets in `lib/widgets/common/`:
- `EmptyState`: Beautiful empty state with icon and action
- `EnhancedEmptyState`: Empty state with more features
- `EnhancedErrorState`: Error display with retry
- `OfflineIndicator`: Shows when offline
- `ShimmerLoading`: Loading placeholder

### Pre-configured Empty States
Use `EmptyStates` class for common scenarios:
```dart
EmptyStates.noTransactions(onAdd, context)
EmptyStates.noBudgets(onAdd, context)
EmptyStates.noGoals(onAdd, context)
EmptyStates.networkError(onRetry, context)
```

---

## Testing

### Test Structure
```
test/
├── widget_test.dart           # Sample widget test
├── services/                 # Service tests
│   ├── error_handler_service_test.dart
│   ├── financial_calculator_test.dart
│   └── form_validators_test.dart
└── widgets/                  # Widget tests
    ├── empty_state_test.dart
    └── financial_summary_card_test.dart
```

### Writing Tests
```dart
void main() {
  group('ServiceName', () {
    test('should do something', () {
      // Arrange
      final service = ServiceName();

      // Act
      final result = service.method();

      // Assert
      expect(result, expectedValue);
    });
  });
}
```

### Testing Best Practices
1. Test business logic in services, not UI
2. Use `group()` to organize related tests
3. Provide descriptive test names
4. Test edge cases and error scenarios
5. Mock dependencies when needed

---

## Styling & Design Tokens

### Design Tokens (`lib/utils/design_tokens.dart`)
All styling constants are centralized:

```dart
// Colors
DesignTokens.primaryColor        // #8B5FBF
DesignTokens.surfaceDark         // #1A1A1A
DesignTokens.successColor       // #4CAF50

// Spacing (8px base)
DesignTokens.spacing4           // 16.0
DesignTokens.spacing8           // 40.0

// Typography
DesignTokens.fontSizeTitleLarge // 22.0
DesignTokens.weightBold         // FontWeight.w700

// Border Radius
DesignTokens.radiusMedium       // 12.0

// Elevation
DesignTokens.elevation2
DesignTokens.cardElevation()
```

### Theme Service
Dark/light theme management via `ThemeService`:
```dart
final themeService = context.watch<ThemeService>();
final theme = Theme.of(context);

// Use theme colors
Color surfaceColor = theme.colorScheme.surface;
Color textColor = theme.colorScheme.onSurface;
```

### Fonts
Use Google Fonts (Poppins):
```dart
Text(
  'Title',
  style: GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  ),
)
```

### Icons
Use `iconsax_flutter` package:
```dart
Icon(Iconsax.home, size: 24)
Icon(Iconsax.wallet, color: DesignTokens.primaryColor)
```

---

## Important Gotchas & Non-Obvious Patterns

### 1. Database Field Names with Suffixes
The SQLite database uses field names with random suffixes (e.g., `transaction_id_232143`):
```dart
// Model parsing handles this automatically
final id = json['transaction_id_232143'] ?? json['id'] ?? '';
```
**Never hardcode these suffixes** - always use the fallback pattern.

### 2. LoggerService Instead of print()
**NEVER use `print()`** - always use `LoggerService`:
```dart
// ❌ WRONG
print('Loading data...');

// ✅ RIGHT
LoggerService.info('Loading data...');
LoggerService.error('Error occurred', error: e);
```
Logs are auto-disabled in release mode via `kDebugMode` check.

### 3. ErrorHandlerService for User Messages
Use `ErrorHandlerService` for all user-facing error messages:
```dart
catch (e) {
  ErrorHandlerService.showErrorSnackbar(
    context,
    ErrorHandlerService.getUserFriendlyMessage(e),
    onRetry: () => _retryAction(),
  );
}
```
Messages are in Indonesian and user-friendly.

### 4. OfflineIndicator in Screens
Always add `OfflineIndicator` to screens:
```dart
Column(
  children: [
    const OfflineIndicator(),
    // Screen content
  ],
)
```

### 5. Standalone Mode - No Backend
The app runs in **standalone mode** with local SQLite:
- No API calls needed for core functionality
- `AppConfig.baseUrl` returns empty string (deprecated)
- All data is local-first

### 6. App Refresh Mechanism
Use `RefreshNotifier` for global refresh notifications:
```dart
// Listen to refresh
RefreshNotifier().addListener(_onGlobalRefresh);

// Trigger refresh
RefreshNotifier().notifyListeners();
```

### 7. Biometric & PIN Auth
- Biometric auth handled by `BiometricService`
- PIN auth by `PinAuthService`
- Check availability before prompting

### 8. Localization Keys
Always provide fallback values:
```dart
Text(l10n?.some_key ?? 'Fallback Text')
```

### 9. Asset Loading
Images and assets must be declared in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - .env
    - assets/images/
```

### 10. Date Parsing
Multiple date formats are handled - use the model's parsing:
```dart
// Don't parse manually - use fromJson
final transaction = TransactionModel.fromJson(json);
```

---

## Code Style & Conventions

### Dart Style
- Follow effective Dart guidelines
- Use `flutter analyze` to check for issues
- Format code with `dart format .`
- Prefer `const` constructors where possible
- Use meaningful variable and function names

### File Organization
- One class per file (except for closely related utility classes)
- Group imports: dart → package → relative
- Keep files under 300 lines when possible
- Extract large widgets to separate files

### Comments
- **NO code comments unless explicitly requested**
- Document public APIs with `///` doc comments
- Keep comments concise and focused on "why", not "what"

### Naming
- Classes: PascalCase (e.g., `TransactionService`)
- Functions/Variables: camelCase (e.g., `fetchTransactions`)
- Constants: camelCase (e.g., `primaryColor`)
- Private members: underscore prefix (e.g., `_loadData()`)

### Null Safety
- Dart is null-safe - use `?` and `!` appropriately
- Use `required` for non-nullable constructor parameters
- Provide sensible defaults or use late initialization

---

## Security Considerations

### Secrets Management
- **NEVER commit** API keys, passwords, or secrets
- Use environment variables via `.env` file (already in .gitignore)
- Use `flutter_secure_storage` for sensitive data on device
- Encrypt sensitive data at rest using `EncryptionService`

### Data Protection
- User data stored locally in SQLite
- PIN-based authentication required to access app
- Biometric authentication as optional enhancement
- AES-256 encryption for sensitive fields

### Network Security
- Use HTTPS for any API calls (if added in future)
- Validate all user inputs
- Sanitize data before storage

### Release Builds
Always build release with obfuscation:
```bash
flutter build apk --release --obfuscate --split-debug-info=./debug-info
```

See `SECURITY.md` for complete security guidelines.

---

## Localization (i18n)

### Adding New Translations
1. Add keys to both `lib/l10n/app_en.arb` and `lib/l10n/app_id.arb`
2. Run `flutter gen-l10n` to generate localization code
3. Use in code:
```dart
final l10n = AppLocalizations.of(context);
Text(l10n?.new_key ?? 'Default value')
```

### Supported Languages
- English (`en`)
- Indonesian (`id`)

### Changing Language
Use `LocalizationService`:
```dart
final localizationService = context.read<LocalizationService>();
localizationService.setLocale(Locale('id', ''));
```

---

## Current Status & Known Issues

### Build Health
| Metric | Status |
|--------|--------|
| `dart analyze` errors | **0** ✅ |
| `dart analyze` warnings | **0** ✅ |
| `dart analyze` info | **202** (info-level only, all pre-existing) |
| `flutter test` | **275/275** ✅ |
| OfflineIndicator on screens | **39/39 (100%)** ✅ |
| Stray `print()` calls | **0** (all via LoggerService) ✅ |
| Hardcoded Colors | **0** (all via DesignTokens) ✅ |
| Hardcoded BorderRadius/EdgeInsets | **0** (all via DesignTokens) ✅ |
| Bang operators (AppLocalizations!) | **0** (33 eliminated) ✅ |

### Critical Bugs Tracked via CODEBASE_AUDIT.md
- **22 CRITICAL** → **0 remaining** (all eliminated)
- **25 HIGH** → **0 remaining** (all eliminated)
- **19 MEDIUM** → **0 remaining** (all eliminated)
- **LOW** → **0 remaining** (all eliminated)
- **UX/Design** → **~0 remaining** (all resolved)
- **UI/Theming (108 items)** → **0 remaining** (465 replacements complete)

### Remaining Items (minor, non-blocking)
- QuickAddWidgetEnhanced voice/scan feature improvements (basic wire-up done)
- Localization pass: some hardcoded Indonesian strings not in ARB files

### Key Technical Details
- **DB Keys**: All tables use `_232143` suffixed column names. Normalization helpers (`_normalizeTransactions`, `_normalize`) in controllers handle the suffix→clean key mapping.
- **Dependency Injection**: All services accessed via `getIt<ServiceType>()` — `ApiService()` constructor banned.
- **Styling**: All colors via `DesignTokens.*` constants in `lib/utils/design_tokens.dart`. No hardcoded `Color(0xFF...)`.

### Branch Info
- Current branch: `sqlite`
- Database: SQLite (local, standalone)
- No backend server required

---

## Common Tasks

### Adding a New Screen
1. Create screen in `lib/features/<feature>/presentation/screens/`
2. Add route in `main.dart`:
```dart
'/new-screen': (context) => const NewScreen(),
```
3. Add `OfflineIndicator` at top
4. Implement with proper error handling
5. Use `LoggerService` for logging
6. Add to navigation as needed

### Adding a New Service
1. Create service in `lib/services/new_service.dart`
2. Register in `lib/core/di/service_locator.dart`:
```dart
getIt.registerLazySingleton<NewService>(() => NewService());
```
3. Use via `getIt<NewService>()`

### Adding a New Widget
1. Create widget in `lib/widgets/feature/new_widget.dart`
2. Make it reusable with proper parameters
3. Follow existing widget patterns
4. Use `DesignTokens` for styling
5. Handle localization

### Updating Models
1. Update model class in `lib/models/`
2. Update `fromJson()` method for backward compatibility
3. Test parsing with existing data
4. Update database schema if needed

---

## Troubleshooting

### Database Issues
- If database fails to initialize, check SQLite file permissions
- Database is created automatically on first run
- Reset app data to clear database: `flutter clean && flutter pub get`

### Build Issues
- Try `flutter clean` then rebuild
- Check Flutter SDK version (requires ^3.7.0)
- Verify all dependencies are compatible

### Localization Issues
- Run `flutter gen-l10n` after modifying ARB files
- Check that keys exist in both en.arb and id.arb files

### Network Issues
- App works offline - network issues shouldn't break core features
- Check `NetworkService` status if needed
- Offline indicator will show when disconnected

---

## Performance Guidelines

### State Management
- Use `const` widgets where possible
- Avoid rebuilding entire trees unnecessarily
- Use `context.read()` vs `context.watch()` appropriately
- Implement `shouldRebuild` for complex widgets

### Lists
- Use `ListView.builder` for long lists
- Implement pagination for large datasets
- Consider `AutomaticKeepAliveClientMixin` for tabs

### Images
- Use appropriate image sizes
- Implement lazy loading for remote images
- Cache images properly

### Services
- Use singleton pattern for services
- Avoid creating new service instances repeatedly
- Dispose streams and controllers properly

---

## Dependency Injection

### Service Locator Setup
All services registered in `lib/core/di/service_locator.dart`:
```dart
Future<void> setupServiceLocator() async {
  // Core Services
  getIt.registerLazySingleton<LoggerService>(() => LoggerService());
  getIt.registerLazySingleton<ApiService>(() => ApiService());

  // Initialize services that need it
  await getIt<NotificationService>().initialize();
}
```

### Accessing Services
```dart
// Anywhere in code
final logger = getIt<LoggerService>();
final apiService = getIt<ApiService>();

// In widgets
final service = getIt<YourService>();
```

### Adding New Services
1. Create service class
2. Register in `setupServiceLocator()`
3. Initialize if needed (async services)
4. Access via `getIt<ServiceType>()`

---

## API Integration (Future Enhancement)

While currently in standalone mode, the app has API service infrastructure:

### ApiService Structure
- Located in `lib/services/api_service.dart`
- Uses HTTP package
- Supports timeout (30 seconds)
- Error handling integrated with ErrorHandlerService

### Adding Backend Integration
1. Configure API base URL in `AppConfig`
2. Implement remote data sources in feature modules
3. Use `ErrorHandlerService` for error messages
4. Implement caching with `CacheService`

---

## Navigation Patterns

### Basic Navigation
```dart
// Push new screen
Navigator.pushNamed(context, '/screen-name');

// Push with arguments
Navigator.pushNamed(
  context,
  '/transaction-detail',
  arguments: {'id': transactionId},
);

// Pop back
Navigator.pop(context);
```

### Tab Navigation
- Home screen uses `PageView` with bottom navigation
- Track current index in state
- Use `_pageController.jumpToPage()` for programmatic navigation

### Modal Bottom Sheets
```dart
showModalBottomSheet(
  context: context,
  builder: (context) => YourModalWidget(),
);
```

---

## Animations

### Use Design Tokens
```dart
// Animation durations
DesignTokens.durationFast     // 150ms
DesignTokens.durationMedium   // 300ms
DesignTokens.durationSlow     // 500ms

// Animation curves
DesignTokens.curveStandard
DesignTokens.curveEmphasized
```

### Common Animations
- Use `AnimatedContainer` for simple transitions
- Use `Hero` for shared element transitions
- Use `PageTransitions` from `lib/utils/page_transitions.dart`

---

## Accessibility

### Touch Targets
- Minimum 48dp for touch targets (see `DesignTokens.touchTargetMin`)

### Screen Reader Support
- Use `Semantics` widgets where needed
- Provide meaningful labels
- Use `AccessibilityHelper` from `lib/utils/accessibility_helper.dart`

### Color Contrast
- Ensure adequate contrast ratios
- Use theme colors that pass WCAG standards

---

## File: Specific Guidelines

### .env File
- Contains environment variables
- Already in .gitignore
- Use `.env.example` as template
- Never commit actual `.env` file

### pubspec.yaml
- All dependencies declared here
- Assets must be listed under `flutter: assets:`
- Use semantic versioning for app version

### analysis_options.yaml
- Configures Dart analyzer
- Uses `flutter_lints` package
- Add custom rules if needed

---

## Git Workflow

### Current Branch
- Working on: `sqlite` branch
- Focus: Local SQLite database, standalone mode

### Commit Pattern
- Use conventional commits:
  - `feat: add new feature`
  - `fix: bug fix`
  - `refactor: code refactoring`
  - `docs: documentation`

### Before Committing
1. Run `flutter analyze`
2. Run `flutter test`
3. Format code with `dart format .`
4. Review changes

---

## Quick Reference

### Imports Order
```dart
import 'dart:async';              // 1. Dart core
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/services/api_service.dart';
import '../widgets/my_widget.dart'; // 2. Relative imports
```

### Common Patterns
```dart
// State with loading/error
bool _isLoading = false;
String? _errorMessage;

// Logger
LoggerService.info('Message');
LoggerService.error('Error', error: e);

// Error handling
catch (e) {
  ErrorHandlerService.showErrorSnackbar(context, e.toString());
}

// Provider access
final state = context.watch<AppState>();
final state = context.read<AppState>();

// Design tokens
DesignTokens.primaryColor
DesignTokens.spacing4
DesignTokens.radiusMedium
```

---

## Resources

### Documentation in Repo
- `README.md` - Project overview and setup
- `SECURITY.md` - Security guidelines and best practices
- `TODO.md` - Current tasks and progress
- `FULL_IMPLEMENTATION_SUMMARY.md` - Implementation status
- `REPLACE_PRINTS_GUIDE.md` - Guide for replacing print statements
- `FIGMA_IMPORT_GUIDE.md` - Design integration guide

### External Resources
- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Guide](https://dart.dev/guides)
- [Provider Package](https://pub.dev/packages/provider)
- [Material Design 3](https://m3.material.io/)

---

## Last Updated
- Generated: 2025
- Branch: sqlite
- Flutter SDK: ^3.7.0
- Dart SDK: ^3.7.0

---

**Remember**: This is a standalone financial app running entirely on local SQLite. No backend server is required. Focus on maintaining this offline-first architecture while ensuring security, performance, and excellent user experience.
