import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/Screen/onboarding_screen.dart';
import 'package:financial_app/Screen/login_screen.dart';
import 'package:financial_app/Screen/home_screen.dart';
import 'package:financial_app/Screen/map_screen.dart';
import 'package:financial_app/Screen/settings_screen.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/data_service.dart';
import 'package:financial_app/state/app_state.dart';

void main() async {
  // Initialize Flutter bindings before making platform channel calls
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final apiService = ApiService();
  final dataService = DataService(apiService);

  // Don't load data here - it will be loaded after login
  // await dataService.refreshAllData();

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(dataService),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Financial App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/map': (context) => const MapScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
