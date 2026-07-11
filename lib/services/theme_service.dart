import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/utils/design_tokens.dart';

enum AppThemeMode { light, dark, system }

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  AppThemeMode _themeMode = AppThemeMode.system; // Default to system

  AppThemeMode get themeMode => _themeMode;

  ThemeService() {
    _loadTheme();
    _listenToSystemTheme();
  }

  /// Listen to system theme changes
  void _listenToSystemTheme() {
    WidgetsBinding
        .instance
        .platformDispatcher
        .onPlatformBrightnessChanged = () {
      if (_themeMode == AppThemeMode.system) {
        notifyListeners();
      }
    };
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_themeKey);

    if (themeModeString != null) {
      _themeMode = AppThemeMode.values.firstWhere(
        (mode) => mode.toString() == themeModeString,
        orElse: () => AppThemeMode.dark,
      );
      notifyListeners();
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.toString());
  }

  /// Get current system brightness
  Brightness get systemBrightness {
    return WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }

  /// Check if system is in dark mode
  bool get isSystemDarkMode {
    return systemBrightness == Brightness.dark;
  }

  ThemeMode getThemeMode() {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: DesignTokens.primaryColor,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      colorScheme: const ColorScheme.light(
        primary: DesignTokens.primaryColor,
        secondary: Color(0xFF6A3093),
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: DesignTokens.surfaceDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: DesignTokens.surfaceDark,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DesignTokens.primaryColor, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: DesignTokens.surfaceDark),
        displayMedium: TextStyle(color: DesignTokens.surfaceDark),
        displaySmall: TextStyle(color: DesignTokens.surfaceDark),
        headlineLarge: TextStyle(color: DesignTokens.surfaceDark),
        headlineMedium: TextStyle(color: DesignTokens.surfaceDark),
        headlineSmall: TextStyle(color: DesignTokens.surfaceDark),
        titleLarge: TextStyle(color: DesignTokens.surfaceDark),
        titleMedium: TextStyle(color: DesignTokens.surfaceDark),
        titleSmall: TextStyle(color: DesignTokens.surfaceDark),
        bodyLarge: TextStyle(color: DesignTokens.surfaceDark),
        bodyMedium: TextStyle(color: DesignTokens.surfaceDark),
        bodySmall: TextStyle(color: Color(0xFF424242)),
        labelLarge: TextStyle(color: DesignTokens.surfaceDark),
        labelMedium: TextStyle(color: DesignTokens.surfaceDark),
        labelSmall: TextStyle(color: Color(0xFF424242)),
      ),
    );
  }

  // Dark Theme (existing)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: DesignTokens.primaryColor,
      scaffoldBackgroundColor: DesignTokens.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: DesignTokens.primaryColor,
        secondary: Color(0xFF6A3093),
        surface: DesignTokens.surfaceDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: DesignTokens.backgroundDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: DesignTokens.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignTokens.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DesignTokens.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DesignTokens.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DesignTokens.primaryColor, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.white),
        displayMedium: TextStyle(color: Colors.white),
        displaySmall: TextStyle(color: Colors.white),
        headlineLarge: TextStyle(color: Colors.white),
        headlineMedium: TextStyle(color: Colors.white),
        headlineSmall: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        bodySmall: TextStyle(color: Colors.white54),
        labelLarge: TextStyle(color: Colors.white),
        labelMedium: TextStyle(color: Colors.white70),
        labelSmall: TextStyle(color: Colors.white54),
      ),
    );
  }

  // Helper method to check if current theme is dark
  bool get isDarkMode {
    return _themeMode == AppThemeMode.dark ||
        (_themeMode == AppThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
  }
}
