import 'package:get_it/get_it.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/local_data_service.dart';
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
import 'package:financial_app/services/analytics_service.dart';
import 'package:financial_app/services/budget_recommendation_service.dart';
import 'package:financial_app/services/budget_predictor.dart';
import 'package:financial_app/services/expense_predictor.dart';
import 'package:financial_app/services/spending_pattern_analyzer.dart';
import 'package:financial_app/services/smart_categorization_service.dart';
import 'package:financial_app/services/goal_forecasting_service.dart';
import 'package:financial_app/services/network_service.dart';
import 'package:financial_app/services/data_service.dart';
import 'package:financial_app/services/obligation_service.dart';
import 'package:financial_app/services/notification_history_service.dart';
import 'package:financial_app/services/obligation_reminder_service.dart';
import 'package:financial_app/services/bill_template_service.dart';
import 'package:financial_app/services/financial_calculator.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/features/transactions/data/datasources/transaction_remote_datasource.dart';
import 'package:financial_app/features/transactions/data/repositories/transaction_repository.dart';
import 'package:financial_app/features/transactions/domain/repositories/transaction_repository_interface.dart';
import 'package:financial_app/features/transactions/domain/use_cases/get_transactions_use_case.dart';
import 'package:financial_app/features/transactions/domain/use_cases/create_transaction_use_case.dart';
import 'package:financial_app/features/transactions/presentation/controllers/transaction_controller.dart';
import 'package:financial_app/features/budgets/data/repositories/budget_repository.dart';
import 'package:financial_app/features/budgets/domain/repositories/budget_repository_interface.dart';
import 'package:financial_app/services/category_customization_service.dart';
import 'package:financial_app/services/net_worth_service.dart';
import 'package:financial_app/services/exchange_rate_service.dart';
import 'package:financial_app/services/account_service.dart';
import 'package:financial_app/services/cash_flow_forecast_service.dart';
import 'package:financial_app/services/debt_service.dart';
import 'package:financial_app/services/expense_split_service.dart';
import 'package:financial_app/services/financial_calendar_service.dart';
import 'package:financial_app/services/investment_service.dart';
import 'package:financial_app/services/subscription_tracker_service.dart';

/// Service Locator untuk Dependency Injection menggunakan get_it
final getIt = GetIt.instance;

/// Setup semua services
Future<void> setupServiceLocator() async {
  // ========== Core Services ==========
  getIt.registerLazySingleton<LoggerService>(() => LoggerService());
  getIt.registerLazySingleton<ErrorHandlerService>(() => ErrorHandlerService());
  getIt.registerLazySingleton<ApiService>(() => ApiService());
  getIt.registerLazySingleton<LocalDataService>(() => LocalDataService());
  getIt.registerLazySingleton<ThemeService>(() => ThemeService());
  getIt.registerLazySingleton<LocalizationService>(() => LocalizationService());

  // ========== Security Services ==========
  getIt.registerLazySingleton<BiometricService>(() => BiometricService());
  getIt.registerLazySingleton<EncryptionService>(() => EncryptionService());

  // ========== Network & Data Services ==========
  getIt.registerLazySingleton<NetworkService>(() => NetworkService());
  getIt.registerLazySingleton<DataService>(
    () => DataService(getIt<ApiService>()),
  );
  getIt.registerLazySingleton<CacheService>(() => CacheService());
  getIt.registerLazySingleton<SearchService>(() => SearchService());
  getIt.registerLazySingleton<ExportService>(() => ExportService());

  // ========== Notification Services ==========
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  getIt.registerLazySingleton<NotificationHistoryService>(
    () => NotificationHistoryService(),
  );
  getIt.registerLazySingleton<ObligationReminderService>(
    () => ObligationReminderService(),
  );

  // ========== Financial Services ==========
  getIt.registerLazySingleton<FinancialCalculator>(() => FinancialCalculator());
  getIt.registerLazySingleton<AnalyticsService>(() => AnalyticsService());
  getIt.registerLazySingleton<SpendingPatternAnalyzer>(
    () => SpendingPatternAnalyzer(),
  );
  getIt.registerLazySingleton<SmartCategorizationService>(
    () => SmartCategorizationService(),
  );
  getIt.registerLazySingleton<GoalForecastingService>(
    () => GoalForecastingService(),
  );
  getIt.registerLazySingleton<ExpensePredictor>(() => ExpensePredictor());
  getIt.registerLazySingleton<BudgetPredictor>(() => BudgetPredictor());
  getIt.registerLazySingleton<BudgetForecastService>(
    () => BudgetForecastService(),
  );
  getIt.registerLazySingleton<BudgetRecommendationService>(
    () => BudgetRecommendationService(),
  );
  getIt.registerLazySingleton<QuickActionsAnalyticsService>(
    () => QuickActionsAnalyticsService(),
  );
  getIt.registerLazySingleton<AIRecommendationsEnhancedService>(
    () => AIRecommendationsEnhancedService(),
  );
  getIt.registerLazySingleton<ObligationService>(() => ObligationService());
  getIt.registerLazySingleton<BillTemplateService>(() => BillTemplateService());

  // ========== Feature Services ==========
  getIt.registerLazySingleton<ReceiptScanningService>(
    () => ReceiptScanningService(),
  );
  getIt.registerLazySingleton<VoiceInputService>(() => VoiceInputService());
  getIt.registerLazySingleton<TransactionTemplatesService>(
    () => TransactionTemplatesService(),
  );

  // ========== Analytics & Monitoring ==========
  getIt.registerLazySingleton<PerformanceService>(() => PerformanceService());
  getIt.registerLazySingleton<UserFeedbackService>(() => UserFeedbackService());

  // ========== Transactions Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<TransactionRemoteDataSource>(
    () => TransactionRemoteDataSource(),
  );

  getIt.registerLazySingleton<TransactionRepositoryInterface>(
    () => TransactionRepository(
      getIt<TransactionRemoteDataSource>(),
      getIt<LocalDataService>(),
    ),
  );

  getIt.registerLazySingleton<GetTransactionsUseCase>(
    () => GetTransactionsUseCase(getIt<TransactionRepositoryInterface>()),
  );
  getIt.registerLazySingleton<CreateTransactionUseCase>(
    () => CreateTransactionUseCase(getIt<TransactionRepositoryInterface>()),
  );

  getIt.registerFactory<TransactionController>(
    () => TransactionController(
      getIt<GetTransactionsUseCase>(),
      getIt<CreateTransactionUseCase>(),
    ),
  );

  // ========== Budgets Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<BudgetRepositoryInterface>(
    () => BudgetRepository(),
  );

  // ========== Domain Services (CRUD operations via LocalDataService) ==========
  getIt.registerLazySingleton<AccountService>(
    () => AccountService(localData: getIt<LocalDataService>()),
  );
  getIt.registerLazySingleton<DebtService>(
    () => DebtService(localData: getIt<LocalDataService>()),
  );
  getIt.registerLazySingleton<SubscriptionTrackerService>(
    () => SubscriptionTrackerService(localData: getIt<LocalDataService>()),
  );
  getIt.registerLazySingleton<InvestmentService>(
    () => InvestmentService(localData: getIt<LocalDataService>()),
  );
  getIt.registerLazySingleton<ExpenseSplitService>(
    () => ExpenseSplitService(localData: getIt<LocalDataService>()),
  );

  // ========== Composite Domain Services (wrap ApiService + other services) ==========
  getIt.registerLazySingleton<CashFlowForecastService>(
    () => CashFlowForecastService(
      apiService: getIt<ApiService>(),
      accountService: getIt<AccountService>(),
    ),
  );
  getIt.registerLazySingleton<FinancialCalendarService>(
    () => FinancialCalendarService(
      apiService: getIt<ApiService>(),
      subscriptionService: getIt<SubscriptionTrackerService>(),
    ),
  );

  // ========== New Feature Services (using LocalDataService) ==========
  getIt.registerLazySingleton(() => CategoryCustomizationService());
  getIt.registerLazySingleton(() => NetWorthService());
  getIt.registerLazySingleton(() => ExchangeRateService());

  // ========== Initialize services ==========
  await getIt<NotificationService>().initialize();
  await getIt<VoiceInputService>().initialize();
  await getIt<NetworkService>().initialize();
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
