import 'package:get_it/get_it.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/theme_service.dart';
import 'package:financial_app/services/notification_service.dart';
import 'package:financial_app/services/biometric_service.dart';
import 'package:financial_app/services/encryption_service.dart';
import 'package:financial_app/services/data/budget_data_service.dart';
import 'package:financial_app/services/data/goal_data_service.dart';
import 'package:financial_app/features/goals/data/repositories/goal_repository.dart';
import 'package:financial_app/features/goals/domain/repositories/goal_repository_interface.dart';
import 'package:financial_app/features/goals/domain/use_cases/get_goals_use_case.dart';
import 'package:financial_app/features/goals/domain/use_cases/create_goal_use_case.dart';
import 'package:financial_app/features/goals/domain/use_cases/delete_goal_use_case.dart';
import 'package:financial_app/features/goals/presentation/controllers/goal_controller.dart';
import 'package:financial_app/features/accounts/data/repositories/account_repository.dart';
import 'package:financial_app/features/accounts/domain/repositories/account_repository_interface.dart';
import 'package:financial_app/features/accounts/domain/use_cases/get_accounts_use_case.dart';
import 'package:financial_app/features/accounts/domain/use_cases/create_account_use_case.dart';
import 'package:financial_app/features/accounts/domain/use_cases/delete_account_use_case.dart';
import 'package:financial_app/features/accounts/presentation/controllers/account_controller.dart';
import 'package:financial_app/features/challenges/data/repositories/challenge_repository.dart';
import 'package:financial_app/features/challenges/domain/repositories/challenge_repository_interface.dart';
import 'package:financial_app/features/challenges/domain/use_cases/get_challenges_use_case.dart';
import 'package:financial_app/features/challenges/domain/use_cases/create_challenge_use_case.dart';
import 'package:financial_app/features/challenges/domain/use_cases/delete_challenge_use_case.dart';
import 'package:financial_app/features/challenges/presentation/controllers/challenge_controller.dart';
import 'package:financial_app/features/debts/data/repositories/debt_repository.dart';
import 'package:financial_app/features/debts/domain/repositories/debt_repository_interface.dart';
import 'package:financial_app/features/debts/domain/use_cases/get_debts_use_case.dart';
import 'package:financial_app/features/debts/domain/use_cases/add_debt_use_case.dart';
import 'package:financial_app/features/debts/domain/use_cases/delete_debt_use_case.dart';
import 'package:financial_app/features/debts/presentation/controllers/debt_controller.dart';
import 'package:financial_app/features/investments/data/repositories/investment_repository.dart';
import 'package:financial_app/features/investments/domain/repositories/investment_repository_interface.dart';
import 'package:financial_app/features/investments/domain/use_cases/get_investments_use_case.dart';
import 'package:financial_app/features/investments/domain/use_cases/add_investment_use_case.dart';
import 'package:financial_app/features/investments/domain/use_cases/delete_investment_use_case.dart';
import 'package:financial_app/features/investments/presentation/controllers/investment_controller.dart';
import 'package:financial_app/features/subscriptions/data/repositories/subscription_repository.dart';
import 'package:financial_app/features/subscriptions/domain/repositories/subscription_repository_interface.dart';
import 'package:financial_app/features/subscriptions/domain/use_cases/get_subscriptions_use_case.dart';
import 'package:financial_app/features/subscriptions/domain/use_cases/add_subscription_use_case.dart';
import 'package:financial_app/features/subscriptions/domain/use_cases/delete_subscription_use_case.dart';
import 'package:financial_app/features/subscriptions/presentation/controllers/subscription_controller.dart';
import 'package:financial_app/features/splits/data/repositories/split_repository.dart';
import 'package:financial_app/features/splits/domain/repositories/split_repository_interface.dart';
import 'package:financial_app/features/splits/domain/use_cases/get_splits_use_case.dart';
import 'package:financial_app/features/splits/domain/use_cases/create_split_use_case.dart';
import 'package:financial_app/features/splits/domain/use_cases/delete_split_use_case.dart';
import 'package:financial_app/features/splits/presentation/controllers/split_controller.dart';
import 'package:financial_app/features/net_worth/data/repositories/net_worth_repository.dart';
import 'package:financial_app/features/net_worth/domain/repositories/net_worth_repository_interface.dart';
import 'package:financial_app/features/net_worth/presentation/controllers/net_worth_controller.dart';
import 'package:financial_app/features/analytics/data/repositories/analytics_repository.dart';
import 'package:financial_app/features/analytics/domain/repositories/analytics_repository_interface.dart';
import 'package:financial_app/features/analytics/presentation/controllers/analytics_controller.dart';
import 'package:financial_app/features/cash_flow/data/repositories/cash_flow_repository.dart';
import 'package:financial_app/features/cash_flow/domain/repositories/cash_flow_repository_interface.dart';
import 'package:financial_app/features/cash_flow/presentation/controllers/cash_flow_controller.dart';
import 'package:financial_app/features/recurring_transactions/data/repositories/recurring_transaction_repository.dart';
import 'package:financial_app/features/recurring_transactions/domain/repositories/recurring_transaction_repository_interface.dart';
import 'package:financial_app/features/recurring_transactions/presentation/controllers/recurring_transaction_controller.dart';
import 'package:financial_app/features/obligations/data/repositories/obligation_repository.dart';
import 'package:financial_app/features/obligations/domain/repositories/obligation_repository_interface.dart';
import 'package:financial_app/features/obligations/presentation/controllers/obligation_controller.dart';
import 'package:financial_app/features/insights/data/repositories/insights_repository.dart';
import 'package:financial_app/features/insights/domain/repositories/insights_repository_interface.dart';
import 'package:financial_app/features/insights/presentation/controllers/insights_controller.dart';
import 'package:financial_app/features/forecast/data/repositories/forecast_repository.dart';
import 'package:financial_app/features/forecast/domain/repositories/forecast_repository_interface.dart';
import 'package:financial_app/features/forecast/presentation/controllers/forecast_controller.dart';
import 'package:financial_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:financial_app/features/backup/presentation/controllers/backup_controller.dart';
import 'package:financial_app/features/backup/data/repositories/backup_repository.dart';
import 'package:financial_app/features/backup/domain/repositories/backup_repository_interface.dart';
import 'package:financial_app/services/data/tag_data_service.dart';
import 'package:financial_app/features/tags/presentation/controllers/tag_controller.dart';
import 'package:financial_app/features/tags/data/repositories/tag_repository.dart';
import 'package:financial_app/features/tags/domain/repositories/tag_repository_interface.dart';
import 'package:financial_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:financial_app/features/profile/data/repositories/profile_repository.dart';
import 'package:financial_app/features/profile/domain/repositories/profile_repository_interface.dart';
import 'package:financial_app/features/receipt_history/data/repositories/receipt_repository.dart';
import 'package:financial_app/features/receipt_history/domain/repositories/receipt_repository_interface.dart';
import 'package:financial_app/features/receipt_history/presentation/controllers/receipt_controller.dart';
import 'package:financial_app/features/report/data/repositories/report_repository.dart';
import 'package:financial_app/features/report/domain/repositories/report_repository_interface.dart';
import 'package:financial_app/features/report/presentation/controllers/report_controller.dart';
import 'package:financial_app/features/templates/data/repositories/template_repository.dart';
import 'package:financial_app/features/templates/domain/repositories/template_repository_interface.dart';
import 'package:financial_app/features/templates/presentation/controllers/template_controller.dart';
import 'package:financial_app/features/notification_center/data/repositories/notification_repository.dart';
import 'package:financial_app/features/notification_center/domain/repositories/notification_repository_interface.dart';
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
import 'package:financial_app/features/budgets/domain/repositories/budget_repository_interface.dart';
import 'package:financial_app/features/budgets/domain/use_cases/get_budgets_use_case.dart';
import 'package:financial_app/features/budgets/domain/use_cases/create_budget_use_case.dart';
import 'package:financial_app/features/budgets/domain/use_cases/update_budget_use_case.dart';
import 'package:financial_app/features/budgets/domain/use_cases/delete_budget_use_case.dart';
import 'package:financial_app/features/budgets/presentation/controllers/budget_controller.dart';

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
      BudgetDataService(),
    ),
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

  // ========== Budgets Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<BudgetRepositoryInterface>(
    () => BudgetRepository(),
  );

  getIt.registerLazySingleton<GetBudgetsUseCase>(
    () => GetBudgetsUseCase(getIt<BudgetRepositoryInterface>()),
  );
  getIt.registerLazySingleton<CreateBudgetUseCase>(
    () => CreateBudgetUseCase(getIt<BudgetRepositoryInterface>()),
  );
  getIt.registerLazySingleton<UpdateBudgetUseCase>(
    () => UpdateBudgetUseCase(getIt<BudgetRepositoryInterface>()),
  );
  getIt.registerLazySingleton<DeleteBudgetUseCase>(
    () => DeleteBudgetUseCase(getIt<BudgetRepositoryInterface>()),
  );

  getIt.registerFactory<BudgetController>(
    () => BudgetController(
      getIt<GetBudgetsUseCase>(),
      getIt<CreateBudgetUseCase>(),
      getIt<DeleteBudgetUseCase>(),
      getIt<UpdateBudgetUseCase>(),
      getIt<BudgetRepositoryInterface>() as BudgetRepository,
    ),
  );

  // ========== Goals Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<GoalRepositoryInterface>(
    () => GoalRepository(goalData: GoalDataService()),
  );

  getIt.registerLazySingleton<GetGoalsUseCase>(
    () => GetGoalsUseCase(getIt<GoalRepositoryInterface>()),
  );
  getIt.registerLazySingleton<CreateGoalUseCase>(
    () => CreateGoalUseCase(getIt<GoalRepositoryInterface>()),
  );
  getIt.registerLazySingleton<DeleteGoalUseCase>(
    () => DeleteGoalUseCase(getIt<GoalRepositoryInterface>()),
  );

  getIt.registerFactory<GoalController>(
    () => GoalController(repository: getIt<GoalRepositoryInterface>()),
  );

  // ========== Accounts Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<AccountRepositoryInterface>(
    () => AccountRepository(accountService: AccountService()),
  );

  getIt.registerLazySingleton<GetAccountsUseCase>(
    () => GetAccountsUseCase(getIt<AccountRepositoryInterface>()),
  );
  getIt.registerLazySingleton<CreateAccountUseCase>(
    () => CreateAccountUseCase(getIt<AccountRepositoryInterface>()),
  );
  getIt.registerLazySingleton<DeleteAccountUseCase>(
    () => DeleteAccountUseCase(getIt<AccountRepositoryInterface>()),
  );

  getIt.registerFactory<AccountController>(
    () => AccountController(repository: getIt<AccountRepositoryInterface>()),
  );

  // ========== Challenges Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<ChallengeRepositoryInterface>(
    () => ChallengeRepository(),
  );

  getIt.registerLazySingleton<GetChallengesUseCase>(
    () => GetChallengesUseCase(getIt<ChallengeRepositoryInterface>()),
  );
  getIt.registerLazySingleton<CreateChallengeUseCase>(
    () => CreateChallengeUseCase(getIt<ChallengeRepositoryInterface>()),
  );
  getIt.registerLazySingleton<DeleteChallengeUseCase>(
    () => DeleteChallengeUseCase(getIt<ChallengeRepositoryInterface>()),
  );

  getIt.registerFactory<ChallengeController>(
    () =>
        ChallengeController(repository: getIt<ChallengeRepositoryInterface>()),
  );

  // ========== Debts Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<DebtRepositoryInterface>(() => DebtRepository());

  getIt.registerLazySingleton<GetDebtsUseCase>(
    () => GetDebtsUseCase(getIt<DebtRepositoryInterface>()),
  );
  getIt.registerLazySingleton<AddDebtUseCase>(
    () => AddDebtUseCase(getIt<DebtRepositoryInterface>()),
  );
  getIt.registerLazySingleton<DeleteDebtUseCase>(
    () => DeleteDebtUseCase(getIt<DebtRepositoryInterface>()),
  );

  getIt.registerFactory<DebtController>(
    () => DebtController(repository: getIt<DebtRepositoryInterface>()),
  );

  // ========== Investments Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<InvestmentRepositoryInterface>(
    () => InvestmentRepository(),
  );
  getIt.registerLazySingleton<GetInvestmentsUseCase>(
    () => GetInvestmentsUseCase(getIt<InvestmentRepositoryInterface>()),
  );
  getIt.registerLazySingleton<AddInvestmentUseCase>(
    () => AddInvestmentUseCase(getIt<InvestmentRepositoryInterface>()),
  );
  getIt.registerLazySingleton<DeleteInvestmentUseCase>(
    () => DeleteInvestmentUseCase(getIt<InvestmentRepositoryInterface>()),
  );
  getIt.registerFactory<InvestmentController>(
    () => InvestmentController(
      repository: getIt<InvestmentRepositoryInterface>(),
    ),
  );

  // ========== Subscriptions Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<SubscriptionRepositoryInterface>(
    () => SubscriptionRepository(),
  );
  getIt.registerLazySingleton<GetSubscriptionsUseCase>(
    () => GetSubscriptionsUseCase(getIt<SubscriptionRepositoryInterface>()),
  );
  getIt.registerLazySingleton<AddSubscriptionUseCase>(
    () => AddSubscriptionUseCase(getIt<SubscriptionRepositoryInterface>()),
  );
  getIt.registerLazySingleton<DeleteSubscriptionUseCase>(
    () => DeleteSubscriptionUseCase(getIt<SubscriptionRepositoryInterface>()),
  );
  getIt.registerFactory<SubscriptionController>(
    () => SubscriptionController(
      repository: getIt<SubscriptionRepositoryInterface>(),
    ),
  );

  // ========== Splits Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<SplitRepositoryInterface>(
    () => SplitRepository(),
  );
  getIt.registerLazySingleton<GetSplitsUseCase>(
    () => GetSplitsUseCase(getIt<SplitRepositoryInterface>()),
  );
  getIt.registerLazySingleton<CreateSplitUseCase>(
    () => CreateSplitUseCase(getIt<SplitRepositoryInterface>()),
  );
  getIt.registerLazySingleton<DeleteSplitUseCase>(
    () => DeleteSplitUseCase(getIt<SplitRepositoryInterface>()),
  );
  getIt.registerFactory<SplitController>(
    () => SplitController(repository: getIt<SplitRepositoryInterface>()),
  );

  // ========== Net Worth Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<NetWorthRepositoryInterface>(
    () => NetWorthRepository(),
  );
  getIt.registerFactory<NetWorthController>(
    () => NetWorthController(repository: getIt<NetWorthRepositoryInterface>()),
  );

  // ========== Analytics Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<AnalyticsRepositoryInterface>(
    () => AnalyticsRepository(),
  );
  getIt.registerFactory<AnalyticsController>(
    () =>
        AnalyticsController(repository: getIt<AnalyticsRepositoryInterface>()),
  );

  // ========== Cash Flow Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<CashFlowRepositoryInterface>(
    () => CashFlowRepository(service: getIt<CashFlowForecastService>()),
  );
  getIt.registerFactory<CashFlowController>(
    () => CashFlowController(repository: getIt<CashFlowRepositoryInterface>()),
  );

  // ========== Recurring Transactions Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<RecurringTransactionRepositoryInterface>(
    () => RecurringTransactionRepository(),
  );
  getIt.registerFactory<RecurringTransactionController>(
    () => RecurringTransactionController(
      repository: getIt<RecurringTransactionRepositoryInterface>(),
    ),
  );

  // ========== Obligations Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<ObligationRepositoryInterface>(
    () => ObligationRepository(service: getIt<ObligationService>()),
  );
  getIt.registerFactory<ObligationController>(
    () => ObligationController(
      repository: getIt<ObligationRepositoryInterface>(),
    ),
  );

  // ========== Insights Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<InsightsRepositoryInterface>(
    () => InsightsRepository(),
  );
  getIt.registerFactory<InsightsController>(
    () => InsightsController(repository: getIt<InsightsRepositoryInterface>()),
  );

  // ========== Forecast Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<ForecastRepositoryInterface>(
    () => ForecastRepository(),
  );
  getIt.registerFactory<ForecastController>(
    () => ForecastController(repository: getIt<ForecastRepositoryInterface>()),
  );

  // ========== Auth Feature (Clean Architecture) ==========
  getIt.registerFactory<AuthController>(() => AuthController());

  // ========== Backup Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<BackupRepositoryInterface>(
    () => BackupRepository(),
  );
  getIt.registerFactory<BackupController>(
    () => BackupController(repository: getIt<BackupRepositoryInterface>()),
  );

  // ========== Tags Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<TagDataService>(() => TagDataService());
  getIt.registerLazySingleton<TagRepositoryInterface>(() => TagRepository());
  getIt.registerFactory<TagController>(
    () => TagController(repository: getIt<TagRepositoryInterface>()),
  );

  // ========== Profile Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<ProfileRepositoryInterface>(
    () => ProfileRepository(),
  );
  getIt.registerFactory<ProfileController>(
    () => ProfileController(repository: getIt<ProfileRepositoryInterface>()),
  );

  // ========== Receipt History Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<ReceiptRepositoryInterface>(
    () => ReceiptRepository(),
  );
  getIt.registerFactory<ReceiptController>(
    () => ReceiptController(repository: getIt<ReceiptRepositoryInterface>()),
  );

  // ========== Report Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<ReportRepositoryInterface>(
    () => ReportRepository(),
  );
  getIt.registerFactory<ReportController>(
    () => ReportController(repository: getIt<ReportRepositoryInterface>()),
  );

  // ========== Templates Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<TemplateRepositoryInterface>(
    () => TemplateRepository(),
  );
  getIt.registerFactory<TemplateController>(
    () => TemplateController(repository: getIt<TemplateRepositoryInterface>()),
  );

  // ========== Notification Center Feature (Clean Architecture) ==========
  getIt.registerLazySingleton<NotificationRepositoryInterface>(
    () => NotificationRepository(),
  );
  getIt.registerFactory<NotificationCenterController>(
    () => NotificationCenterController(
      repository: getIt<NotificationRepositoryInterface>(),
    ),
  );

  // ========== Category Customization Feature (Clean Architecture) ==========
  getIt.registerFactory<CategoryController>(() => CategoryController());

  // ========== Calendar Feature (Clean Architecture) ==========
  getIt.registerFactory<CalendarController>(
    () => CalendarController(service: getIt<FinancialCalendarService>()),
  );

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
  getIt.registerLazySingleton<DebtService>(() => DebtService());
  getIt.registerLazySingleton<SubscriptionTrackerService>(
    () => SubscriptionTrackerService(),
  );
  getIt.registerLazySingleton<InvestmentService>(() => InvestmentService());
  getIt.registerLazySingleton<ExpenseSplitService>(() => ExpenseSplitService());

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
