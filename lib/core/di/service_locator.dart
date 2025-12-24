import 'package:get_it/get_it.dart';
import 'package:financial_app/services/api_service.dart';
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

/// Service Locator untuk Dependency Injection menggunakan get_it
final getIt = GetIt.instance;

/// Setup semua services
Future<void> setupServiceLocator() async {
  // Core Services
  getIt.registerLazySingleton<LoggerService>(() => LoggerService());
  getIt.registerLazySingleton<ApiService>(() => ApiService());
  getIt.registerLazySingleton<ThemeService>(() => ThemeService());
  
  // Notification Service (needs initialization)
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  
  // Security Services
  getIt.registerLazySingleton<BiometricService>(() => BiometricService());
  getIt.registerLazySingleton<EncryptionService>(() => EncryptionService());
  
  // Data Services
  getIt.registerLazySingleton<CacheService>(() => CacheService());
  getIt.registerLazySingleton<SearchService>(() => SearchService());
  getIt.registerLazySingleton<ExportService>(() => ExportService());
  
  // Analytics & Monitoring
  getIt.registerLazySingleton<PerformanceService>(() => PerformanceService());
  getIt.registerLazySingleton<UserFeedbackService>(() => UserFeedbackService());
  getIt.registerLazySingleton<QuickActionsAnalyticsService>(
    () => QuickActionsAnalyticsService(),
  );
  
  // Financial Services
  getIt.registerLazySingleton<BudgetForecastService>(
    () => BudgetForecastService(),
  );
  getIt.registerLazySingleton<AIRecommendationsEnhancedService>(
    () => AIRecommendationsEnhancedService(),
  );
  
  // Initialize services that need it
  await getIt<NotificationService>().initialize();
  getIt<PerformanceService>().startMemoryMonitoring();
  getIt<PerformanceService>().startSession();
}

/// Dispose semua services
Future<void> disposeServiceLocator() async {
  getIt<PerformanceService>().stopMemoryMonitoring();
  getIt<PerformanceService>().endSession();
  await getIt.reset();
}

