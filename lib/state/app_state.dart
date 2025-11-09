import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../services/data_service.dart';

class AppState extends ChangeNotifier {
  final DataService _dataService;
  final List<StreamSubscription> _subscriptions = [];

  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  Map<String, dynamic> _financialSummary = {};
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;

  AppState(this._dataService) {
    _subscribeToDataStreams();
  }

  void _subscribeToDataStreams() {
    // Subscribe to data streams
    _subscriptions.add(
      _dataService.transactions.listen(
        (data) {
          if (!_isDisposed) {
            _transactions =
                data.map((json) => TransactionModel.fromJson(json)).toList();
            notifyListeners();
          }
        },
        onError: (e) {
          if (!_isDisposed) {
            _error = e.toString();
            notifyListeners();
          }
        },
      ),
    );

    _subscriptions.add(
      _dataService.categories.listen(
        (data) {
          if (!_isDisposed) {
            _categories =
                data.map((json) => CategoryModel.fromJson(json)).toList();
            notifyListeners();
          }
        },
        onError: (e) {
          if (!_isDisposed) {
            _error = e.toString();
            notifyListeners();
          }
        },
      ),
    );

    _subscriptions.add(
      _dataService.financialSummary.listen(
        (data) {
          if (!_isDisposed) {
            _financialSummary = data;
            notifyListeners();
          }
        },
        onError: (e) {
          if (!_isDisposed) {
            _error = e.toString();
            notifyListeners();
          }
        },
      ),
    );
  }

  // Getters
  List<TransactionModel> get transactions => _transactions;
  List<CategoryModel> get categories => _categories;
  Map<String, dynamic> get financialSummary => _financialSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Methods
  Future<void> refreshData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _dataService.refreshAllData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filtered getters
  List<TransactionModel> getTransactionsByType(String type) {
    return _transactions.where((t) => t.type == type).toList();
  }

  List<TransactionModel> getTransactionsByCategory(String categoryId) {
    return _transactions.where((t) => t.categoryId == categoryId).toList();
  }

  List<CategoryModel> getCategoriesByType(String type) {
    return _categories.where((c) => c.type == type).toList();
  }

  @override
  void dispose() {
    _isDisposed = true;
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }
}
