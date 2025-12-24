import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/services/logger_service.dart';

/// Service untuk managing app localization
class LocalizationService extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  Locale _currentLocale = const Locale('id'); // Default to Indonesian

  Locale get currentLocale => _currentLocale;

  LocalizationService() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeString = prefs.getString(_localeKey);
      
      if (localeString != null) {
        final parts = localeString.split('_');
        _currentLocale = Locale(parts[0], parts.length > 1 ? parts[1] : null);
        notifyListeners();
      }
    } catch (e) {
      LoggerService.error('Error loading locale', error: e);
    }
  }

  Future<void> setLocale(Locale locale) async {
    try {
      _currentLocale = locale;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.toString());
      
      LoggerService.debug('Locale changed to: ${locale.toString()}');
    } catch (e) {
      LoggerService.error('Error setting locale', error: e);
    }
  }

  List<Locale> get supportedLocales => [
    const Locale('id', 'ID'),
    const Locale('en', 'US'),
  ];

  String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'id':
        return 'Bahasa Indonesia';
      case 'en':
        return 'English';
      default:
        return locale.languageCode;
    }
  }
}

