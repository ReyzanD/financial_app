import 'package:get_it/get_it.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/theme_service.dart';
import 'package:financial_app/services/notification_service.dart';
import 'package:financial_app/services/biometric_service.dart';
import 'package:financial_app/services/encryption_service.dart';
import 'package:financial_app/services/data/category_data_service.dart';
import 'package:financial_app/services/data/budget_data_service.dart';
import 'package:financial_app/services/data/transaction_template_data_service.dart';
import 'package:financial_app/services/data/goal_data_service.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';
import 'package:financial_app/services/data/receipt_scan_data_service.dart';
import 'package:financial_app/services/data/exchange_rate_data_service.dart';
import 'package:financial_app/services/data/net_worth_data_service.dart';
import 'package:financial_app/features/goals/data/repositories/goal_repository.dart';
import 'package:financial_app/features/goals/domain/repositories/goal_repository_interface.dart';
import 'package:financial_app/features/goals/domain/use_cases/get_goals_use_case.dart';
import 'package:financial_app/features/goals/domain/use_cases/create_goal_use_case.dart';
import 'package:financial_app/features/goals/domain/use_cases/delete_goal_use_case.dart';
import 'package:financial_app/features/goals/presentation/controllers/goal_controller.dart';
import 'package:financial_app/features/accounts/data/repositories/account_repository.dart';
import 'package:financial_app/features/accounts/presentation/controllers/account_controller.dart';
import 'package:financial_app/features/challenges/data/repositories/challenge_repository.dart';
import 'package:financial_app/features/challenges/presentation/controllers/challenge_controller.dart';
import 'package:financial_app/features/investments/data/repositories/investment_repository.dart';
import 'package:financial_app/features/investments/presentation/controllers/investment_controller.dart';
import 'package:financial_app/features/splits/data/repositories/split_repository.dart';
import 'package:financial_app/features/splits/presentation/controllers/split_controller.dart';
import 'package:financial_app/features/net_worth/data/repositories/net_worth_repository.dart';
import 'package:financial_app/features/net_worth/presentation/controllers/net_worth_controller.dart';
import 'package:financial_app/features/analytics/data/repositories/analytics_repository.dart';

import 'package:financial_app/features/analytics/presentation/controllers/analytics_controller.dart';
import 'package:financial_app/features/cash_flow/data/repositories/cash_flow_repository.dart';
import 'package:financial_app/features/cash_flow/presentation/controllers/cash_flow_controller.dart';
import 'package:financial_app/features/obligations/data/repositories/obligation_repository.dart';
import 'package:financial_app/features/obligations/presentation/controllers/obligation_controller.dart';
import 'package:financial_app/features/insights/data/repositories/insights_repository.dart';
import 'package:financial_app/features/insights/presentation/controllers/insights_controller.dart';
import 'package:financial_app/features/forecast/data/repositories/forecast_repository.dart';
import 'package:financial_app/features/forecast/presentation/controllers/forecast_controller.dart';
import 'package:financial_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:financial_app/features/backup/presentation/controllers/backup_controller.dart';
import 'package:financial_app/features/backup/data/repositories/backup_repository.dart';
import 'package:financial_app/services/data/tag_data_service.dart';
import 'package:financial_app/services/data/investment_data_service.dart';
import 'package:financial_app/services/data/account_data_service.dart';
import 'package:financial_app/services/data/obligation_data_service.dart';
import 'package:financial_app/services/data/place_visit_data_service.dart';
import 'package:financial_app/services/data/price_observation_data_service.dart';
import 'package:financial_app/services/data/alternative_suggestion_data_service.dart';
import 'package:financial_app/services/osm_category_mapping_service.dart';
import 'package:financial_app/services/overpass_api_service.dart';
import 'package:financial_app/services/alternative_recommendation_engine.dart';
import 'package:financial_app/services/location_intelligence_service.dart';
import 'package:financial_app/services/location_recommendations_enhanced_service.dart';
import 'package:financial_app/services/financial_advisor_service.dart';

import 'package:financial_app/services/data/challenge_data_service.dart';
import 'package:financial_app/features/tags/presentation/controllers/tag_controller.dart';
import 'package:financial_app/features/tags/data/repositories/tag_repository.dart';
import 'package:financial_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:financial_app/features/profile/data/repositories/profile_repository.dart';

import 'package:financial_app/features/receipt_history/data/repositories/receipt_repository.dart';
import 'package:financial_app/features/receipt_history/presentation/controllers/receipt_controller.dart';
import 'package:financial_app/features/report/data/repositories/report_repository.dart';
import 'package:financial_app/features/report/presentation/controllers/report_controller.dart';
import 'package:financial_app/features/templates/data/repositories/template_repository.dart';
import 'package:financial_app/features/templates/presentation/controllers/template_controller.dart';
import 'package:financial_app/features/notification_center/data/repositories/notification_repository.dart';
import 'package:financial_app/features/notification_center/presentation/controllers/notification_center_controller.dart';
import 'package:financial_app/features/category_customization/presentation/controllers/category_controller.dart';
import 'package:financial_app/features/financial_calendar/presentation/controllers/calendar_controller.dart';
import 'package:financial_app/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:financial_app/features/ai_budget_recommendation/presentation/controllers/ai_budget_controller.dart';
import 'package:financial_app/features/settings/presentation/controllers/settings_controller.dart';
import 'package:financial_app/features/home/presentation/controllers/dashboard_controller.dart';
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
import 'package:financial_app/services/backup_service.dart';
import 'package:financial_app/services/payment_history_service.dart';
import 'package:financial_app/services/ai_service.dart';
import 'package:financial_app/services/net_worth_service.dart';
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
import 'package:financial_app/features/transactions/domain/use_cases/delete_transaction_use_case.dart';
import 'package:financial_app/features/transactions/presentation/controllers/transaction_controller.dart';
import 'package:financial_app/features/budgets/data/repositories/budget_repository.dart';
import 'package:financial_app/features/budgets/presentation/controllers/budget_controller.dart';

import 'package:financial_app/services/account_service.dart';
import 'package:financial_app/services/cash_flow_forecast_service.dart';
import 'package:financial_app/services/expense_split_service.dart';
import 'package:financial_app/services/financial_calendar_service.dart';
import 'package:financial_app/services/investment_service.dart';

/// Service Locator untuk Dependency Injection menggunakan get_it
final getIt = GetIt.instance;

/// Setup semua services
Future<void> setupServiceLocator() async {
  // ========== Core Services ==========
  getIt.registerLazySingleton<LoggerService>(() => LoggerService());
  getIt.registerLazySingleton<ErrorHandlerService>(() => ErrorHandlerService());
  getIt.registerLazySingleton<ObligationDataService>(() => ObligationDataService());
  getIt.registerLazySingleton<ThemeService>(() => ThemeService());
  getIt.registerLazySingleton<LocalizationService>(() => LocalizationService());

  // ========== Security Services ==========
  getIt.registerLazySingleton<BiometricService>(() => BiometricService());
  getIt.registerLazySingleton<EncryptionService>(() => EncryptionService());

  // ========== Network & Data Services ==========
  getIt.registerLazySingleton<NetworkService>(() => NetworkService());
  getIt.registerLazySingleton<DataService>(() => DataService());
  getIt.registerLazySingleton<CacheService>(() => CacheService());
  getIt.registerLazySingleton<SearchService>(() => SearchService());
  getIt.registerLazySingleton<ExportService>(() => ExportService());

  // ========== Notification Services ==========
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  getIt.registerLazySingleton<NotificationHistoryService>(() => NotificationHistoryService());
  getIt.registerLazySingleton<ObligationReminderService>(() => ObligationReminderService());

  // ========== Financial Services ==========
  getIt.registerLazySingleton<FinancialCalculator>(() => FinancialCalculator());
  getIt.registerLazySingleton<AnalyticsService>(() => AnalyticsService());
  getIt.registerLazySingleton<SpendingPatternAnalyzer>(() => SpendingPatternAnalyzer());
  getIt.registerLazySingleton<SmartCategorizationService>(() => SmartCategorizationService());
  getIt.registerLazySingleton<GoalForecastingService>(() => GoalForecastingService());
  getIt.registerLazySingleton<ExpensePredictor>(() => ExpensePredictor());
  getIt.registerLazySingleton<BudgetPredictor>(() => BudgetPredictor());
  getIt.registerLazySingleton<BudgetForecastService>(() => BudgetForecastService());
  getIt.registerLazySingleton<BudgetRecommendationService>(() => BudgetRecommendationService());
  getIt.registerLazySingleton<QuickActionsAnalyticsService>(() => QuickActionsAnalyticsService());
  getIt.registerLazySingleton<AIRecommendationsEnhancedService>(() => AIRecommendationsEnhancedService());
  getIt.registerLazySingleton<ObligationService>(() => ObligationService());
  getIt.registerLazySingleton<BillTemplateService>(() => BillTemplateService());

  // ========== Business Services ==========
  getIt.registerLazySingleton<NetWorthService>(() => NetWorthService());
  getIt.registerLazySingleton<BackupService>(() => BackupService());
  getIt.registerLazySingleton<PaymentHistoryService>(() => PaymentHistoryService());
  getIt.registerLazySingleton<AIService>(() => AIService());

  // ========== Feature Services ==========
  getIt.registerLazySingleton<ReceiptScanningService>(() => ReceiptScanningService());
  getIt.registerLazySingleton<VoiceInputService>(() => VoiceInputService());
  getIt.registerLazySingleton<TransactionTemplatesService>(() => TransactionTemplatesService());

  // ========== Analytics & Monitoring ==========
  getIt.registerLazySingleton<PerformanceService>(() => PerformanceService());
  getIt.registerLazySingleton<UserFeedbackService>(() => UserFeedbackService());

  // ========== Transactions Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<TransactionRemoteDataSource>(() => TransactionRemoteDataSource());

  getIt.registerLazySingleton<TransactionRepositoryInterface>(
    () => TransactionRepository(getIt<TransactionRemoteDataSource>(), getIt<BudgetDataService>()),
  );

  getIt.registerLazySingleton<GetTransactionsUseCase>(
    () => GetTransactionsUseCase(getIt<TransactionRepositoryInterface>()),
  );
  getIt.registerLazySingleton<CreateTransactionUseCase>(
    () => CreateTransactionUseCase(getIt<TransactionRepositoryInterface>()),
  );
  getIt.registerLazySingleton<DeleteTransactionUseCase>(
    () => DeleteTransactionUseCase(getIt<TransactionRepositoryInterface>()),
  );

  getIt.registerFactory<TransactionController>(
    () => TransactionController(
      getIt<GetTransactionsUseCase>(),
      getIt<CreateTransactionUseCase>(),
      getIt<DeleteTransactionUseCase>(),
    ),
  );

  // ========== Budgets Feature ==========
  getIt.registerLazySingleton<BudgetRepository>(() => BudgetRepository());
  getIt.registerFactory<BudgetController>(() => BudgetController(getIt<BudgetRepository>()));

  // ========== Goals Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<GoalRepositoryInterface>(() => GoalRepository(goalData: getIt<GoalDataService>()));

  getIt.registerLazySingleton<GetGoalsUseCase>(() => GetGoalsUseCase(getIt<GoalRepositoryInterface>()));
  getIt.registerLazySingleton<CreateGoalUseCase>(() => CreateGoalUseCase(getIt<GoalRepositoryInterface>()));
  getIt.registerLazySingleton<DeleteGoalUseCase>(() => DeleteGoalUseCase(getIt<GoalRepositoryInterface>()));

  getIt.registerFactory<GoalController>(() => GoalController(repository: getIt<GoalRepositoryInterface>()));

  // ========== Accounts Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<AccountRepository>(() => AccountRepository(accountService: getIt<AccountService>()));

  getIt.registerFactory<AccountController>(() => AccountController(repository: getIt<AccountRepository>()));

  // ========== Challenges Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<ChallengeDataService>(() => ChallengeDataService());
  getIt.registerLazySingleton<ChallengeRepository>(
    () => ChallengeRepository(challengeData: getIt<ChallengeDataService>()),
  );

  getIt.registerFactory<ChallengeController>(() => ChallengeController(repository: getIt<ChallengeRepository>()));

  // ========== Investments Feature ==========
  getIt.registerLazySingleton<InvestmentRepository>(() => InvestmentRepository());
  getIt.registerFactory<InvestmentController>(() => InvestmentController(repository: getIt<InvestmentRepository>()));

  // ========== Splits Feature ==========
  getIt.registerLazySingleton<SplitRepository>(() => SplitRepository());
  getIt.registerFactory<SplitController>(() => SplitController(repository: getIt<SplitRepository>()));

  // ========== Net Worth Feature ==========
  getIt.registerLazySingleton<NetWorthRepository>(() => NetWorthRepository());
  getIt.registerFactory<NetWorthController>(() => NetWorthController(repository: getIt<NetWorthRepository>()));

  // ========== Analytics Feature ==========
  getIt.registerLazySingleton<AnalyticsRepository>(() => AnalyticsRepository());
  getIt.registerFactory<AnalyticsController>(() => AnalyticsController(repository: getIt<AnalyticsRepository>()));

  // ========== Cash Flow Feature ==========
  getIt.registerLazySingleton<CashFlowRepository>(() => CashFlowRepository(service: getIt<CashFlowForecastService>()));
  getIt.registerFactory<CashFlowController>(() => CashFlowController(repository: getIt<CashFlowRepository>()));

  // ========== Obligations Feature ==========
  getIt.registerLazySingleton<ObligationRepository>(() => ObligationRepository(service: getIt<ObligationService>()));
  getIt.registerFactory<ObligationController>(() => ObligationController(repository: getIt<ObligationRepository>()));

  // ========== Insights Feature ==========
  getIt.registerLazySingleton<InsightsRepository>(() => InsightsRepository());
  getIt.registerFactory<InsightsController>(() => InsightsController(repository: getIt<InsightsRepository>()));

  // ========== Forecast Feature ==========
  getIt.registerLazySingleton<ForecastRepository>(() => ForecastRepository());
  getIt.registerFactory<ForecastController>(() => ForecastController(repository: getIt<ForecastRepository>()));

  // ========== Auth Feature (Clean Architecture) ==========
  getIt.registerFactory<AuthController>(() => AuthController());

  // ========== Backup Feature ==========
  getIt.registerLazySingleton<BackupRepository>(() => BackupRepository());
  getIt.registerFactory<BackupController>(() => BackupController(repository: getIt<BackupRepository>()));

  // ========== Tags Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<TagDataService>(() => TagDataService());
  getIt.registerLazySingleton<TagRepository>(() => TagRepository());
  getIt.registerFactory<TagController>(() => TagController(repository: getIt<TagRepository>()));

  // ========== Profile Feature ==========
  getIt.registerLazySingleton<ProfileRepository>(() => ProfileRepository());
  getIt.registerFactory<ProfileController>(() => ProfileController(repository: getIt<ProfileRepository>()));

  // ========== Receipt History Feature ==========
  getIt.registerLazySingleton<ReceiptRepository>(() => ReceiptRepository());
  getIt.registerFactory<ReceiptController>(() => ReceiptController(repository: getIt<ReceiptRepository>()));

  // ========== Report Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<ReportRepository>(() => ReportRepository());
  getIt.registerFactory<ReportController>(() => ReportController(repository: getIt<ReportRepository>()));

  // ========== Templates Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<TransactionTemplateDataService>(() => TransactionTemplateDataService());
  getIt.registerLazySingleton<TemplateRepository>(
    () => TemplateRepository(service: getIt<TransactionTemplateDataService>()),
  );
  getIt.registerFactory<TemplateController>(() => TemplateController(repository: getIt<TemplateRepository>()));

  // ========== Notification Center Feature ==========
  getIt.registerLazySingleton<NotificationRepository>(() => NotificationRepository());
  getIt.registerFactory<NotificationCenterController>(
    () => NotificationCenterController(repository: getIt<NotificationRepository>()),
  );

  // ========== Category Customization Feature (Clean Architecture) ==========
  getIt.registerFactory<CategoryController>(() => CategoryController());

  // ========== Calendar Feature (Clean Architecture) ==========
  getIt.registerFactory<CalendarController>(() => CalendarController(service: getIt<FinancialCalendarService>()));

  // ========== Map Feature (no controller registration - uses direct state) ==========

  // ========== Onboarding Feature (Clean Architecture) ==========
  getIt.registerFactory<OnboardingController>(() => OnboardingController());

  // ========== AI Budget Recommendation Feature (Clean Architecture) ==========
  getIt.registerFactory<AIBudgetController>(() => AIBudgetController());

  // ========== Settings Feature (Clean Architecture) ==========
  getIt.registerFactory<SettingsController>(() => SettingsController());

  // ========== Dashboard Feature ==========
  getIt.registerFactory<DashboardController>(() => DashboardController());

  // ========== Domain Services (CRUD operations via focused data services) ==========
  getIt.registerLazySingleton<AccountService>(() => AccountService());
  getIt.registerLazySingleton<AccountDataService>(() => AccountDataService());
  getIt.registerLazySingleton<InvestmentDataService>(() => InvestmentDataService());
  getIt.registerLazySingleton<InvestmentService>(() => InvestmentService());
  getIt.registerLazySingleton<ExpenseSplitService>(() => ExpenseSplitService());

  // ========== Data Services (CRUD operations) ==========
  getIt.registerLazySingleton<CategoryDataService>(() => CategoryDataService());
  getIt.registerLazySingleton<GoalDataService>(() => GoalDataService());
  getIt.registerLazySingleton<TransactionDataService>(() => TransactionDataService());
  getIt.registerLazySingleton<BudgetDataService>(() => BudgetDataService());
  getIt.registerLazySingleton<ReceiptScanDataService>(() => ReceiptScanDataService());
  getIt.registerLazySingleton<ExchangeRateDataService>(() => ExchangeRateDataService());
  getIt.registerLazySingleton<NetWorthDataService>(() => NetWorthDataService());

  // ========== Phase 2: Alternative Recommendation Services ==========
  getIt.registerLazySingleton<PlaceVisitDataService>(() => PlaceVisitDataService());
  getIt.registerLazySingleton<PriceObservationDataService>(() => PriceObservationDataService());
  getIt.registerLazySingleton<AlternativeSuggestionDataService>(() => AlternativeSuggestionDataService());
  getIt.registerLazySingleton<OsmCategoryMappingService>(() => OsmCategoryMappingService());
  getIt.registerLazySingleton<OverpassApiService>(() => OverpassApiService());
  getIt.registerLazySingleton<AlternativeRecommendationEngine>(() => AlternativeRecommendationEngine());
  getIt.registerLazySingleton<LocationIntelligenceService>(() => LocationIntelligenceService());
  getIt.registerLazySingleton<LocationRecommendationsEnhancedService>(() => LocationRecommendationsEnhancedService());

  // ========== Phase 3: Financial Advisor Service ==========
  getIt.registerLazySingleton<FinancialAdvisorService>(() => FinancialAdvisorService());

  // ========== Composite Domain Services ==========
  getIt.registerLazySingleton<CashFlowForecastService>(
    () => CashFlowForecastService(
      transactionData: getIt<TransactionDataService>(),
      accountService: getIt<AccountService>(),
    ),
  );
  getIt.registerLazySingleton<FinancialCalendarService>(
    () => FinancialCalendarService(
      transactionData: getIt<TransactionDataService>(),
      obligationData: getIt<ObligationDataService>(),
    ),
  );

  // ========== Initialize services ==========
  await getIt<NotificationService>().initialize();
  await getIt<VoiceInputService>().initialize();
  await getIt<NetworkService>().initialize();
  getIt<PerformanceService>().startMemoryMonitoring();
  getIt<PerformanceService>().startSession();

  // ========== Phase 2 startup sync: transactions → PlaceVisits ==========
  try {
    await getIt<PlaceVisitDataService>().syncFromTransactions(getIt<TransactionDataService>());
  } catch (e) {
    LoggerService.error('PlaceVisit startup sync failed (non-fatal)', error: e);
  }
}

/// Dispose semua services
Future<void> disposeServiceLocator() async {
  getIt<PerformanceService>().stopMemoryMonitoring();
  getIt<PerformanceService>().endSession();
  getIt<ReceiptScanningService>().dispose();
  await getIt.reset();
}
