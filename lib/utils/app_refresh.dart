import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/state/app_state.dart';
import 'package:financial_app/services/logger_service.dart';

/// Notification sent when data needs to be refreshed
class DataRefreshNotification extends Notification {}

/// Global stream controller for triggering refreshes
class RefreshNotifier extends ChangeNotifier {
  static final RefreshNotifier _instance = RefreshNotifier._internal();
  factory RefreshNotifier() => _instance;
  RefreshNotifier._internal();

  void triggerRefresh() {
    LoggerService.debug('[RefreshNotifier] Triggering refresh...');
    notifyListeners();
  }
}

/// Global utility to trigger app-wide data refresh
class AppRefresh {
  /// Trigger a forced refresh of all app data
  /// Call this after any mutation operation (add/edit/delete)
  static Future<void> refreshAll(BuildContext context) async {
    try {
      LoggerService.debug('[AppRefresh] Forcing app-wide data refresh...');

      // Refresh AppState (this updates Provider-based widgets)
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.refreshData(forceRefresh: true);

      // Send notification to widgets listening for refresh
      DataRefreshNotification().dispatch(context);

      // Trigger global refresh notifier (for home screen)
      RefreshNotifier().triggerRefresh();

      LoggerService.success('[AppRefresh] Refresh completed successfully');
    } catch (e) {
      LoggerService.error('[AppRefresh] Error during refresh', error: e);
    }
  }

  /// Show a refresh indicator while refreshing
  static Future<void> refreshWithIndicator(BuildContext context) async {
    // Note: Removed delay - refresh immediately for better UX
    await refreshAll(context);
  }
}
