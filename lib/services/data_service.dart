import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:financial_app/services/api_service.dart';

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
    // Immediately start data updates
    startPeriodicUpdates();
  }

  void startPeriodicUpdates() {
    // Fetch initial data
    refreshAllData();

    // Set up periodic updates every 30 seconds
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      refreshAllData();
    });
  }

  bool _isRefreshing = false;
  DateTime? _lastRefresh;

  Future<void> refreshAllData() async {
    // Prevent multiple simultaneous refreshes
    if (_isRefreshing) return;

    // Don't refresh more often than every 5 seconds
    if (_lastRefresh != null &&
        DateTime.now().difference(_lastRefresh!) < const Duration(seconds: 5)) {
      return;
    }

    _isRefreshing = true;
    try {
      // Fetch all data types in parallel
      await Future.wait([
        refreshTransactions(),
        refreshCategories(),
        refreshFinancialSummary(),
      ]);
      _lastRefresh = DateTime.now();
    } catch (e) {
      print('Error refreshing data: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> refreshTransactions() async {
    try {
      final transactions = await _apiService.getTransactions();
      if (!_transactionsController.isClosed) {
        _transactionsController.add(transactions);
      }
    } catch (e) {
      print('Error fetching transactions: $e');
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
      print('Error fetching categories: $e');
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
      print('Error fetching financial summary: $e');
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
