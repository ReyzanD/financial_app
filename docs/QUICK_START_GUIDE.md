# Quick Start Guide - New Features

## 🚀 Voice Input & Receipt Scanning

### Voice Input
```dart
import 'package:financial_app/services/voice_input_service.dart';
import 'package:financial_app/core/di/service_locator_enhanced.dart';

// Get service
final voiceService = getIt<VoiceInputService>();

// Start listening
final result = await voiceService.startListening(
  localeId: 'id_ID',
  listenDuration: Duration(seconds: 5),
);

if (result != null) {
  // Use recognized text
  print('Recognized: $result');
}
```

### Receipt Scanning
```dart
import 'package:financial_app/services/receipt_scanning_service.dart';

// Get service
final receiptService = getIt<ReceiptScanningService>();

// Pick and scan
final imageFile = await receiptService.pickImage(fromCamera: true);
if (imageFile != null) {
  final scanResult = await receiptService.scanReceipt(imageFile);
  
  if (scanResult != null) {
    final parsed = scanResult['parsed_data'];
    final amount = parsed['total']; // Extracted amount
    final merchant = parsed['merchant']; // Extracted merchant
    // Use data...
  }
}
```

## 🏗️ Clean Architecture Usage

### Using Transaction Controller
```dart
import 'package:financial_app/core/di/service_locator_enhanced.dart';
import 'package:financial_app/features/transactions/presentation/controllers/transaction_controller.dart';

// Get controller
final controller = getIt<TransactionController>();

// Load transactions
await controller.loadTransactions(
  type: 'expense',
  startDate: DateTime.now().subtract(Duration(days: 30)),
);

// Access data
final transactions = controller.transactions;
final isLoading = controller.isLoading;
```

### Using Use Cases Directly
```dart
import 'package:financial_app/core/di/service_locator_enhanced.dart';
import 'package:financial_app/features/transactions/domain/use_cases/get_transactions_use_case.dart';

// Get use case
final useCase = getIt<GetTransactionsUseCase>();

// Execute
final transactions = await useCase(
  type: 'expense',
  limit: 20,
);
```

## 🌍 Localization

```dart
import 'package:financial_app/l10n/app_localizations.dart';

// In widget
final l10n = AppLocalizations.of(context);

// Use translations
Text(l10n.addTransaction)
Text(l10n.formatCurrency(50000)) // "Rp 50.000"
Text(l10n.formatDate(DateTime.now()))
```

## 📊 Performance Monitoring

```dart
import 'package:financial_app/services/performance_service.dart';

final perfService = getIt<PerformanceService>();

// Track screen load
perfService.startScreenTracking('home_screen');
// ... screen loads ...
perfService.endScreenTracking('home_screen');

// Track API calls
perfService.recordApiResponseTime('/api/transactions', 250);

// Get summary
final summary = perfService.getPerformanceSummary();
```

## 🔍 Global Search

```dart
import 'package:financial_app/services/search_service.dart';

final searchService = getIt<SearchService>();

// Search transactions
final results = await searchService.globalSearch(
  query: 'makan',
  entityTypes: ['transactions', 'budgets', 'goals'],
);
```

## 📤 Export/Import

```dart
import 'package:financial_app/services/export_service.dart';

final exportService = getIt<ExportService>();

// Export to CSV
final csvPath = await exportService.exportTransactionsToCSV(
  startDate: DateTime.now().subtract(Duration(days: 30)),
  type: 'expense',
);

// Share file
await exportService.shareFile(csvPath);
```

---

Semua fitur siap digunakan! 🎉

