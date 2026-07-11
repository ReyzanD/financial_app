import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:financial_app/features/analytics/domain/repositories/analytics_repository_interface.dart';
import 'package:financial_app/services/logger_service.dart';

class AnalyticsController extends ChangeNotifier {
  final AnalyticsRepositoryInterface _r;
  AnalyticsController({required AnalyticsRepositoryInterface repository}) : _r = repository;

  String _selectedPeriod = '';
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _transactions = [];
  Map<String, dynamic> _summary = {};

  String get selectedPeriod => _selectedPeriod;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get transactions => _transactions;
  Map<String, dynamic> get summary => _summary;

  /// Normalize raw DB maps (with _232143 suffixed keys) to clean keys.
  /// The SQL query uses `t.*` which returns suffixed keys plus JOIN aliases
  /// (e.g. `c.name_232143 AS category_name`) that are already clean.
  /// This ensures ALL consumers see consistent clean keys regardless.
  List<Map<String, dynamic>> _normalizeTransactions(List<dynamic> txns) {
    return txns.map((t) {
      final map = t as Map<String, dynamic>;
      final rawAmount = (map['amount_232143'] ?? map['amount']);
      return {
        'transaction_date': map['transaction_date_232143'] ?? map['transaction_date'] ?? map['date'],
        'date': map['transaction_date_232143'] ?? map['transaction_date'] ?? map['date'],
        'type': map['type_232143'] ?? map['type'],
        'amount': (rawAmount is num) ? rawAmount.toDouble() : 0.0,
        'category_name': map['category_name_232143'] ?? map['category_name'] ?? 'Lainnya',
        'category': map['category_name_232143'] ?? map['category_name'] ?? 'Uncategorized',
        'category_color': map['category_color_232143'] ?? map['category_color'] ?? '#8B5FBF',
        'category_id': map['category_id_232143'] ?? map['category_id'],
        'description': map['description_232143'] ?? map['description'] ?? '',
        'transaction_id': map['transaction_id_232143'] ?? map['transaction_id'] ?? map['id'],
        'id': map['transaction_id_232143'] ?? map['id'] ?? map['transaction_id'],
        'account_id': map['account_id_232143'] ?? map['account_id'],
        'payment_method': map['payment_method_232143'] ?? map['payment_method'],
      };
    }).toList();
  }

  void initializePeriod(String period) {
    if (_selectedPeriod.isEmpty && period.isNotEmpty) {
      _selectedPeriod = period;
      notifyListeners();
    }
  }

  void setPeriod(String period) {
    _selectedPeriod = period;
    notifyListeners();
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      LoggerService.debug('Loading analytics data...');
      final now = DateTime.now();
      DateTime? startDate;
      final endDate = now;

      // Parse period into date range
      if (_selectedPeriod.isNotEmpty) {
        startDate = _resolvePeriod(now, _selectedPeriod);
      }

      final transactionsData = await _r.getTransactions(limit: 100, startDate: startDate, endDate: endDate);
      final summary = await _r.getFinancialSummary(year: now.year, month: now.month);

      final rawTransactions = List<dynamic>.from(transactionsData['transactions'] ?? []);
      _transactions = _normalizeTransactions(rawTransactions);
      _summary = summary;

      LoggerService.success('Loaded ${_transactions.length} transactions');
      LoggerService.debug('Summary loaded', error: summary);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      LoggerService.error('Error loading analytics', error: e);
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  DateTime? _resolvePeriod(DateTime now, String period) {
    final today = DateTime(now.year, now.month, now.day);
    // Period strings are compared broadly since they vary by locale
    final lower = period.toLowerCase();
    if (lower.contains('week') || lower.contains('minggu')) {
      return today.subtract(Duration(days: today.weekday - 1));
    }
    if (lower.contains('month') || lower.contains('bulan') || lower.contains('3')) {
      if (lower.contains('3') || lower.contains('three')) {
        return DateTime(now.year, now.month - 2, 1);
      }
      return DateTime(now.year, now.month, 1);
    }
    if (lower.contains('year') || lower.contains('tahun')) {
      return DateTime(now.year, 1, 1);
    }
    return null;
  }

  Future<void> refresh() async => loadData();
}
