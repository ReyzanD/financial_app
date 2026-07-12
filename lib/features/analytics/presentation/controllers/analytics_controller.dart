import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:financial_app/features/analytics/domain/repositories/analytics_repository_interface.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/utils/key_normalizer.dart';

class AnalyticsController extends ChangeNotifier {
  final AnalyticsRepositoryInterface _r;
  AnalyticsController({required AnalyticsRepositoryInterface repository})
    : _r = repository;

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

      final transactionsData = await _r.getTransactions(
        limit: 100,
        startDate: startDate,
        endDate: endDate,
      );
      final summary = await _r.getFinancialSummary(
        year: now.year,
        month: now.month,
      );

      final rawTransactions = List<dynamic>.from(
        transactionsData['transactions'] ?? [],
      );
      _transactions = KeyNormalizer.normalizeTransactions(rawTransactions);
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
    if (lower.contains('month') ||
        lower.contains('bulan') ||
        lower.contains('3')) {
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
