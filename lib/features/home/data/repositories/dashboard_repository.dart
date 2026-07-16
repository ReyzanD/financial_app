import 'dart:async';
import 'package:financial_app/state/app_state.dart';
import 'package:financial_app/core/di/service_locator.dart';

/// Dashboard Repository - delegates to AppState for refresh orchestration.
class DashboardRepository {
  final AppState _appState;

  DashboardRepository({AppState? appState})
      : _appState = appState ?? getIt<AppState>();

  Future<void> refreshData({bool forceRefresh = true}) async {
    return await _appState.refreshData(forceRefresh: forceRefresh);
  }

  Future<void> loadInitialData() async {
    return await _appState.loadInitialData();
  }
}
