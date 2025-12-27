import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/Screen/onboarding_screen.dart';
import 'package:financial_app/Screen/login_screen.dart';
import 'package:financial_app/Screen/home_screen.dart';
import 'package:financial_app/Screen/map_screen.dart';
import 'package:financial_app/Screen/settings_screen.dart';
import 'package:financial_app/Screen/pin_setup_screen.dart';
import 'package:financial_app/Screen/pin_unlock_screen.dart';
import 'package:financial_app/Screen/pin_change_screen.dart';
import 'package:financial_app/Screen/auth_gate.dart';
import 'package:financial_app/Screen/notification_center_screen.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/data_service.dart';
import 'package:financial_app/services/notification_service.dart';
import 'package:financial_app/services/network_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/theme_service.dart';
import 'package:financial_app/services/map_provider_service.dart';
import 'package:financial_app/services/localization_service.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/core/app_config.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/state/app_state.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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

  // Initialize services
  final apiService = ApiService();
  final dataService = DataService(apiService);

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  // Initialize network monitoring
  final networkService = NetworkService();
  await networkService.initialize();

  // Don't load data here - it will be loaded after login
  // await dataService.refreshAllData();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppState(dataService)),
        ChangeNotifierProvider(create: (context) => ThemeService()),
        ChangeNotifierProvider(create: (context) => LocalizationService()),
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
      backgroundColor: Colors.black,
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
                    backgroundColor: const Color(0xFF8B5FBF),
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
