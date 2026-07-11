import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:financial_app/features/auth/presentation/screens/login_screen.dart';

import 'package:financial_app/features/home/presentation/screens/home_screen.dart';
import 'package:financial_app/features/map/presentation/screens/map_screen.dart';
import 'package:financial_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:financial_app/features/auth/presentation/screens/pin_setup_screen.dart';
import 'package:financial_app/features/auth/presentation/screens/pin_unlock_screen.dart';
import 'package:financial_app/features/auth/presentation/screens/pin_change_screen.dart';
import 'package:financial_app/features/auth/presentation/screens/auth_gate_screen.dart';
import 'package:financial_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:financial_app/features/backup/presentation/screens/backup_screen.dart';
import 'package:financial_app/features/backup/presentation/controllers/backup_controller.dart';
import 'package:financial_app/features/tags/presentation/screens/tags_screen.dart';
import 'package:financial_app/features/tags/presentation/controllers/tag_controller.dart';
import 'package:financial_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:financial_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:financial_app/features/budgets/presentation/screens/budgets_screen.dart';
import 'package:financial_app/features/goals/presentation/screens/goals_screen.dart';
import 'package:financial_app/features/goals/presentation/controllers/goal_controller.dart';
import 'package:financial_app/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:financial_app/features/analytics/presentation/controllers/analytics_controller.dart';

import 'package:financial_app/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:financial_app/features/ai_budget_recommendation/presentation/screens/ai_budget_recommendation_screen.dart';
import 'package:financial_app/features/obligations/presentation/screens/financial_obligations_screen.dart';
import 'package:financial_app/features/obligations/presentation/controllers/obligation_controller.dart';
import 'package:financial_app/features/forecast/presentation/screens/forecast_screen.dart';
import 'package:financial_app/features/forecast/presentation/controllers/forecast_controller.dart';
import 'package:financial_app/features/recurring_transactions/presentation/screens/recurring_transactions_screen.dart';
import 'package:financial_app/features/recurring_transactions/presentation/controllers/recurring_transaction_controller.dart';
import 'package:financial_app/features/transactions/presentation/screens/transaction_history_screen.dart';
import 'package:financial_app/features/transactions/presentation/controllers/transaction_controller.dart';
import 'package:financial_app/features/budgets/presentation/controllers/budget_controller.dart';
import 'package:financial_app/features/insights/presentation/screens/financial_insights_screen.dart';
import 'package:financial_app/features/insights/presentation/controllers/insights_controller.dart';
import 'package:financial_app/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:financial_app/features/accounts/presentation/controllers/account_controller.dart';
import 'package:financial_app/features/debts/presentation/screens/debts_screen.dart';
import 'package:financial_app/features/debts/presentation/controllers/debt_controller.dart';
import 'package:financial_app/features/subscriptions/presentation/screens/subscriptions_screen.dart';
import 'package:financial_app/features/subscriptions/presentation/controllers/subscription_controller.dart';
import 'package:financial_app/features/investments/presentation/screens/investments_screen.dart';
import 'package:financial_app/features/investments/presentation/controllers/investment_controller.dart';
import 'package:financial_app/features/splits/presentation/screens/splits_screen.dart';
import 'package:financial_app/features/splits/presentation/controllers/split_controller.dart';
import 'package:financial_app/features/challenges/presentation/screens/challenges_screen.dart';
import 'package:financial_app/features/challenges/presentation/controllers/challenge_controller.dart';
import 'package:financial_app/features/net_worth/presentation/screens/net_worth_screen.dart';
import 'package:financial_app/features/net_worth/presentation/controllers/net_worth_controller.dart';
import 'package:financial_app/features/cash_flow/presentation/screens/cash_flow_screen.dart';
import 'package:financial_app/features/cash_flow/presentation/controllers/cash_flow_controller.dart';
import 'package:financial_app/features/templates/presentation/screens/templates_screen.dart';
import 'package:financial_app/features/templates/presentation/controllers/template_controller.dart';
import 'package:financial_app/features/notification_center/presentation/screens/notification_center_screen.dart';
import 'package:financial_app/features/notification_center/presentation/controllers/notification_center_controller.dart';
import 'package:financial_app/features/category_customization/presentation/screens/category_customization_screen.dart';
import 'package:financial_app/features/category_customization/presentation/controllers/category_controller.dart';
import 'package:financial_app/features/financial_calendar/presentation/screens/financial_calendar_screen.dart';
import 'package:financial_app/features/financial_calendar/presentation/controllers/calendar_controller.dart';
import 'package:financial_app/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:financial_app/features/ai_budget_recommendation/presentation/controllers/ai_budget_controller.dart';
import 'package:financial_app/features/settings/presentation/controllers/settings_controller.dart';
import 'package:financial_app/features/receipt_history/presentation/screens/receipt_history_screen.dart';
import 'package:financial_app/features/receipt_history/presentation/controllers/receipt_controller.dart';
import 'package:financial_app/features/report/presentation/screens/report_screen.dart';
import 'package:financial_app/features/report/presentation/controllers/report_controller.dart';
import 'package:financial_app/services/data_service.dart';
import 'package:financial_app/services/notification_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/theme_service.dart';
import 'package:financial_app/services/map_provider_service.dart';
import 'package:financial_app/services/localization_service.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/core/app_config.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/state/app_state.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:financial_app/utils/design_tokens.dart';

void main() async {
  // Initialize Flutter bindings before making platform channel calls
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  Map<String, String>? envMap;
  try {
    // Try loading .env file
    await dotenv.load(fileName: '.env');
    envMap = dotenv.env;
    LoggerService.debug('[Main] Loaded .env file with ${envMap.length} keys');
  } catch (e) {
    LoggerService.warning('Could not load .env file, using defaults: $e');
  }

  // Initialize MapProviderService with env map
  await MapProviderService.initialize(envMap);

  // Initialize Local Database (replaces backend server)
  try {
    await LocalDatabaseService().database;
    LoggerService.info('✅ Local database initialized');
  } catch (e) {
    LoggerService.error('Failed to initialize local database', error: e);
  }

  // Initialize AppConfig (no longer needs URL for standalone mode)
  await AppConfig.initialize();

  // Setup global error handlers
  _setupErrorHandlers();

  // Setup Service Locator (get_it DI)
  await setupServiceLocator();

  // Initialize notifications
  final notificationService = getIt<NotificationService>();
  await notificationService.requestPermissions();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AppState(getIt<DataService>()),
        ),
        ChangeNotifierProvider(create: (context) => ThemeService()),
        ChangeNotifierProvider(create: (context) => LocalizationService()),
        ChangeNotifierProvider(
          create: (context) => getIt<TransactionController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<BudgetController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<GoalController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<AccountController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<ChallengeController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<DebtController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<InvestmentController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<SubscriptionController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<SplitController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<NetWorthController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<AnalyticsController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<CashFlowController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<RecurringTransactionController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<ObligationController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<InsightsController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<ForecastController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<AuthController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<BackupController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<TagController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<ProfileController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<ReceiptController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<ReportController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<TemplateController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<NotificationCenterController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<CategoryController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<CalendarController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<OnboardingController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<AIBudgetController>(),
        ),
        ChangeNotifierProvider(
          create: (context) => getIt<SettingsController>(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

/// Setup global error handlers for better error management
void _setupErrorHandlers() {
  // Handle Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    LoggerService.error(
      'Flutter framework error: ${details.library}',
      error: details.exception,
      stackTrace: details.stack,
    );

    // In debug mode, show the default error UI
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };

  // Handle errors outside of Flutter framework (async errors)
  PlatformDispatcher.instance.onError = (error, stack) {
    LoggerService.error(
      'Uncaught error outside Flutter framework',
      error: error,
      stackTrace: stack,
    );
    return true; // Return true to prevent default error handling
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeService, LocalizationService>(
      builder: (context, themeService, localizationService, child) {
        return MaterialApp(
          title: 'Financial App',
          debugShowCheckedModeBanner: false,
          theme: ThemeService.lightTheme,
          darkTheme: ThemeService.darkTheme,
          themeMode: themeService.getThemeMode(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: localizationService.supportedLocales,
          locale: localizationService.currentLocale,
          // Custom error widget for better UX
          builder: (context, widget) {
            ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
              return _buildErrorWidget(context, errorDetails);
            };
            return widget ?? const SizedBox.shrink();
          },
          initialRoute: '/',
          routes: {
            '/': (context) => const AuthGate(),
            '/login': (context) => const LoginScreen(),
            '/pin-setup': (context) => const PinSetupScreen(),
            '/pin-unlock': (context) => const PinUnlockScreen(),
            '/pin-change': (context) => const PinChangeScreen(),
            '/notifications': (context) => const NotificationCenterScreen(),
            '/home': (context) => const HomeScreen(),
            '/onboarding': (context) => const OnboardingScreen(),
            '/map': (context) => const MapScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/budgets': (context) => const BudgetsScreen(),
            '/analytics': (context) => const AnalyticsScreen(),
            '/goals': (context) => const GoalsScreen(),
            '/add-transaction': (context) => const AddTransactionScreen(),
            '/ai-budget-recommendation':
                (context) => const AIBudgetRecommendationScreen(),
            '/reports': (context) => const ReportScreen(),
            '/backup': (context) => const BackupScreen(),
            '/financial-obligations':
                (context) => const FinancialObligationsScreen(),
            '/forecast': (context) => const ForecastScreen(),
            '/recurring-transactions':
                (context) => const RecurringTransactionsScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/transaction-history':
                (context) => const TransactionHistoryScreen(),
            '/receipt-history': (context) => const ReceiptHistoryScreen(),
            '/financial-insights': (context) => const FinancialInsightsScreen(),
            '/accounts': (context) => const AccountsScreen(),
            '/debts': (context) => const DebtsScreen(),
            '/subscriptions': (context) => const SubscriptionsScreen(),
            '/investments': (context) => const InvestmentsScreen(),
            '/tags': (context) => const TagsScreen(),
            '/splits': (context) => const SplitsScreen(),
            '/challenges': (context) => const ChallengesScreen(),
            '/calendar': (context) => const FinancialCalendarScreen(),
            '/net-worth': (context) => const NetWorthScreen(),
            '/cash-flow': (context) => const CashFlowScreen(),
            '/categories': (context) => const CategoryCustomizationScreen(),
            '/templates': (context) => const TemplatesScreen(),
          },
        );
      },
    );
  }

  /// Build a user-friendly error widget
  Widget _buildErrorWidget(
    BuildContext context,
    FlutterErrorDetails errorDetails,
  ) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 24),
                Text(
                  'Terjadi Kesalahan',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Aplikasi mengalami masalah. Silakan restart aplikasi.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Debug Info:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          errorDetails.exception.toString(),
                          style: TextStyle(
                            color: Colors.red[300],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Try to navigate back or restart
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
