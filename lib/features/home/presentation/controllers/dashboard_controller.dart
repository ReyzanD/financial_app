import 'package:flutter/material.dart';
import 'package:financial_app/features/home/data/repositories/dashboard_repository.dart';

/// Coordinates dashboard-level refresh orchestration.
///
/// Dashboard widgets currently fetch their own data from ApiService
/// directly. This controller provides a single refresh coordination
/// point so the home screen and FAB don't need to reach into AppState
/// directly for that purpose.
class DashboardController extends ChangeNotifier {
  final DashboardRepository _repository;

  DashboardController({DashboardRepository? repository})
      : _repository = repository ?? DashboardRepository();

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  String? _error;
  String? get error => _error;

  /// Refresh all dashboard data.
  ///
  /// Triggers AppState's refreshData (which feeds DataService streams)
  /// and increments the refresh counter so downstream widgets re-fetch.
  Future<void> refresh() async {
    _isRefreshing = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.refreshData(forceRefresh: true);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Load initial data on first launch.
  Future<void> loadInitialData() async {
    _isRefreshing = true;
    notifyListeners();

    try {
      await _repository.loadInitialData();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }
}
