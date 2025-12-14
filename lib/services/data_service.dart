import 'dart:async';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/logger_service.dart';

class DataService {
  final ApiService _apiService;

  // Stream controllers for real-time data
  final _transactionsController = StreamController<List<dynamic>>.broadcast();
  final _categoriesController = StreamController<List<dynamic>>.broadcast();
  final _financialSummaryController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters for streams
  Stream<List<dynamic>> get transactions => _transactionsController.stream;
  Stream<List<dynamic>> get categories => _categoriesController.stream;
  Stream<Map<String, dynamic>> get financialSummary =>
      _financialSummaryController.stream;

  // Timer for periodic updates
  Timer? _updateTimer;

  DataService(this._apiService) {
    // Don't start periodic updates immediately
    // Wait for explicit data load after authentication
    LoggerService.info(
      '[DataService] Service initialized, waiting for data load',
    );
  }

  void startPeriodicUpdates() {
    // Stop any existing timer
    _updateTimer?.cancel();

    // Fetch initial data
    refreshAllData();

    // Set up periodic updates every 2 minutes (reduced from 30s for better performance)
    _updateTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      refreshAllData();
    });

    LoggerService.info(
      '[DataService] Periodic updates started (every 2 minutes)',
    );
  }

  bool _isRefreshing = false;
  DateTime? _lastRefresh;

  Future<void> refreshAllData({bool forceRefresh = false}) async {
    // If forced, allow immediate refresh
    if (forceRefresh) {
      // Wait for ongoing refresh to complete if any
      if (_isRefreshing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } else {
      // Prevent multiple simultaneous refreshes
      if (_isRefreshing) return;

      // Don't refresh more often than every 2 seconds (reduced from 5)
      if (_lastRefresh != null &&
          DateTime.now().difference(_lastRefresh!) <
              const Duration(seconds: 2)) {
        LoggerService.debug(
          'Skipping refresh - throttled (last refresh: ${DateTime.now().difference(_lastRefresh!).inSeconds}s ago)',
        );
        return;
      }
    }

    _isRefreshing = true;
    try {
      LoggerService.info('Refreshing all data (forced: $forceRefresh)');

      // Clear API cache on force refresh to get fresh data
      if (forceRefresh) {
        ApiService.clearCache();
      }

      // Fetch all data types in parallel
      await Future.wait([
        refreshTransactions(),
        refreshCategories(),
        refreshFinancialSummary(),
      ]);
      _lastRefresh = DateTime.now();
    } catch (e) {
      LoggerService.error('Error refreshing data', error: e);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> refreshTransactions() async {
    try {
      LoggerService.info('[DataService] Fetching transactions from API...');
      final transactions = await _apiService.getTransactions();
      LoggerService.success(
        '[DataService] Received ${transactions.length} transactions from API',
      );
      if (!_transactionsController.isClosed) {
        _transactionsController.add(transactions);
        LoggerService.debug('[DataService] Transactions pushed to stream');
      }
    } catch (e) {
      LoggerService.error(
        '[DataService] Error fetching transactions',
        error: e,
      );
      if (!_transactionsController.isClosed) {
        _transactionsController.add([]); // Add empty list on error
      }
    }
  }

  Future<void> refreshCategories() async {
    try {
      final categories = await _apiService.getCategories();
      if (!_categoriesController.isClosed) {
        _categoriesController.add(categories);
      }
    } catch (e) {
      LoggerService.error('Error fetching categories', error: e);
      if (!_categoriesController.isClosed) {
        _categoriesController.add([]); // Add empty list on error
      }
    }
  }

  Future<void> refreshFinancialSummary() async {
    try {
      final summary = await _apiService.getFinancialSummary();
      if (!_financialSummaryController.isClosed) {
        _financialSummaryController.add(summary);
      }
    } catch (e) {
      LoggerService.error('Error fetching financial summary', error: e);
      if (!_financialSummaryController.isClosed) {
        _financialSummaryController.add({}); // Add empty map on error
      }
    }
  }

  void dispose() {
    _updateTimer?.cancel();
    _transactionsController.close();
    _categoriesController.close();
    _financialSummaryController.close();
  }
}
