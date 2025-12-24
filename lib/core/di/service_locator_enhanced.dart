import 'package:get_it/get_it.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/theme_service.dart';
import 'package:financial_app/services/notification_service.dart';
import 'package:financial_app/services/biometric_service.dart';
import 'package:financial_app/services/encryption_service.dart';
import 'package:financial_app/services/cache_service.dart';
import 'package:financial_app/services/search_service.dart';
import 'package:financial_app/services/export_service.dart';
import 'package:financial_app/services/performance_service.dart';
import 'package:financial_app/services/user_feedback_service.dart';
import 'package:financial_app/services/budget_forecast_service.dart';
import 'package:financial_app/services/quick_actions_analytics_service.dart';
import 'package:financial_app/services/ai_recommendations_enhanced_service.dart';
import 'package:financial_app/services/voice_input_service.dart';
import 'package:financial_app/services/receipt_scanning_service.dart';
import 'package:financial_app/services/transaction_templates_service.dart';
import 'package:financial_app/services/localization_service.dart';
import 'package:financial_app/features/transactions/data/datasources/transaction_remote_datasource.dart';
import 'package:financial_app/features/transactions/data/repositories/transaction_repository.dart';
import 'package:financial_app/features/transactions/domain/repositories/transaction_repository_interface.dart';
import 'package:financial_app/features/transactions/domain/use_cases/get_transactions_use_case.dart';
import 'package:financial_app/features/transactions/domain/use_cases/create_transaction_use_case.dart';
import 'package:financial_app/features/transactions/presentation/controllers/transaction_controller.dart';
import 'package:financial_app/features/budgets/data/repositories/budget_repository.dart';
import 'package:financial_app/features/budgets/domain/repositories/budget_repository_interface.dart';

/// Enhanced Service Locator dengan Clean Architecture support
final getIt = GetIt.instance;

/// Setup semua services dengan Clean Architecture pattern
Future<void> setupServiceLocator() async {
  // ========== Core Services ==========
  getIt.registerLazySingleton<LoggerService>(() => LoggerService());
  getIt.registerLazySingleton<ThemeService>(() => ThemeService());
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  getIt.registerLazySingleton<BiometricService>(() => BiometricService());
  getIt.registerLazySingleton<EncryptionService>(() => EncryptionService());
  getIt.registerLazySingleton<CacheService>(() => CacheService());
  getIt.registerLazySingleton<LocalizationService>(() => LocalizationService());

  // ========== Feature Services ==========
  getIt.registerLazySingleton<SearchService>(() => SearchService());
  getIt.registerLazySingleton<ExportService>(() => ExportService());
  getIt.registerLazySingleton<PerformanceService>(() => PerformanceService());
  getIt.registerLazySingleton<UserFeedbackService>(() => UserFeedbackService());
  getIt.registerLazySingleton<BudgetForecastService>(() => BudgetForecastService());
  getIt.registerLazySingleton<QuickActionsAnalyticsService>(
    () => QuickActionsAnalyticsService(),
  );
  getIt.registerLazySingleton<AIRecommendationsEnhancedService>(
    () => AIRecommendationsEnhancedService(),
  );
  getIt.registerLazySingleton<VoiceInputService>(() => VoiceInputService());
  getIt.registerLazySingleton<ReceiptScanningService>(() => ReceiptScanningService());
  getIt.registerLazySingleton<TransactionTemplatesService>(
    () => TransactionTemplatesService(),
  );

  // ========== Transactions Feature (Clean Architecture) ==========
  // Data Sources
  getIt.registerLazySingleton<TransactionRemoteDataSource>(
    () => TransactionRemoteDataSource(),
  );

  // Repositories
  getIt.registerLazySingleton<TransactionRepositoryInterface>(
    () => TransactionRepository(getIt<TransactionRemoteDataSource>()),
  );

  // Use Cases
  getIt.registerLazySingleton<GetTransactionsUseCase>(
    () => GetTransactionsUseCase(getIt<TransactionRepositoryInterface>()),
  );
  getIt.registerLazySingleton<CreateTransactionUseCase>(
    () => CreateTransactionUseCase(getIt<TransactionRepositoryInterface>()),
  );

  // Controllers
  getIt.registerFactory<TransactionController>(
    () => TransactionController(
      getIt<GetTransactionsUseCase>(),
      getIt<CreateTransactionUseCase>(),
    ),
  );

  // ========== Budgets Feature (Clean Architecture) ==========
  // Repositories
  getIt.registerLazySingleton<BudgetRepositoryInterface>(
    () => BudgetRepository(),
  );

  // Initialize services that need it
  await getIt<NotificationService>().initialize();
  await getIt<VoiceInputService>().initialize();
  getIt<PerformanceService>().startMemoryMonitoring();
  getIt<PerformanceService>().startSession();
}

/// Dispose semua services
Future<void> disposeServiceLocator() async {
  getIt<PerformanceService>().stopMemoryMonitoring();
  getIt<PerformanceService>().endSession();
  getIt<ReceiptScanningService>().dispose();
  await getIt.reset();
}

