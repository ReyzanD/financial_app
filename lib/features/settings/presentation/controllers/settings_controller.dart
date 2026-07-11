import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/services/auth_service.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/core/di/service_locator.dart';

class SettingsController extends ChangeNotifier {
  final AuthService _auth = getIt<AuthService>();
  final ApiService _api = getIt<ApiService>();

  bool _aiRecommendationsEnabled = true;
  bool _locationServicesEnabled = true;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  int _defaultTabIndex = 0;

  bool get aiRecommendationsEnabled => _aiRecommendationsEnabled;
  bool get locationServicesEnabled => _locationServicesEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkModeEnabled => _darkModeEnabled;
  int get defaultTabIndex => _defaultTabIndex;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _aiRecommendationsEnabled = prefs.getBool('ai_recommendations_enabled') ?? true;
    _locationServicesEnabled = prefs.getBool('location_services_enabled') ?? true;
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? true;
    _defaultTabIndex = prefs.getInt('default_tab_index') ?? 0;
    notifyListeners();
  }

  Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  void toggleAi(bool v) { _aiRecommendationsEnabled = v; notifyListeners(); setBool('ai_recommendations_enabled', v); }
  void toggleLocation(bool v) { _locationServicesEnabled = v; notifyListeners(); setBool('location_services_enabled', v); }
  void toggleNotifications(bool v) { _notificationsEnabled = v; notifyListeners(); setBool('notifications_enabled', v); }
  void toggleDarkMode(bool v) { _darkModeEnabled = v; notifyListeners(); setBool('dark_mode_enabled', v); }
  void setDefaultTab(int index) { _defaultTabIndex = index; notifyListeners(); setInt('default_tab_index', index); }

  Future<void> logout() async {
    await _auth.logout();
  }

  Future<void> deleteAccount() async {
    await _auth.deleteAccount();
  }

  Future<Map<String, dynamic>> exportData({int limit = 10000}) async {
    final transactions = await _api.getTransactions(limit: limit);
    final budgets = await _api.getBudgets();
    final goals = await _api.getGoals();
    return {
      'exported_at': DateTime.now().toIso8601String(),
      'stats': {
        'total_transactions': transactions['total'] ?? 0,
        'budgets': budgets.length,
        'goals': goals.length,
      },
    };
  }
}
