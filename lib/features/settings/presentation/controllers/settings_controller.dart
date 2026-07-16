import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/features/settings/data/repositories/settings_repository.dart';

class SettingsController extends ChangeNotifier {
  final SettingsRepository _repository;

  SettingsController({SettingsRepository? repository})
    : _repository = repository ?? getIt<SettingsRepository>();

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
    _aiRecommendationsEnabled =
        prefs.getBool('ai_recommendations_enabled') ?? true;
    _locationServicesEnabled =
        prefs.getBool('location_services_enabled') ?? true;
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

  void toggleAi(bool v) {
    _aiRecommendationsEnabled = v;
    notifyListeners();
    setBool('ai_recommendations_enabled', v);
  }

  void toggleLocation(bool v) {
    _locationServicesEnabled = v;
    notifyListeners();
    setBool('location_services_enabled', v);
  }

  void toggleNotifications(bool v) {
    _notificationsEnabled = v;
    notifyListeners();
    setBool('notifications_enabled', v);
  }

  void toggleDarkMode(bool v) {
    _darkModeEnabled = v;
    notifyListeners();
    setBool('dark_mode_enabled', v);
  }

  void setDefaultTab(int index) {
    _defaultTabIndex = index;
    notifyListeners();
    setInt('default_tab_index', index);
  }

  Future<void> logout() async {
    await _repository.logout();
  }

  Future<void> deleteAccount() async {
    await _repository.deleteAccount();
  }

  Future<Map<String, dynamic>> exportData() async {
    final transactions = await _repository.exportAllTransactions();
    final budgets = await _repository.getBudgets();
    final goals = await _repository.getGoals();
    return {
      'exported_at': DateTime.now().toIso8601String(),
      'transactions': transactions,
      'stats': {
        'total_transactions': transactions.length,
        'budgets': budgets.length,
        'goals': goals.length,
      },
    };
  }
}
