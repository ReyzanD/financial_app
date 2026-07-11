import 'package:flutter/foundation.dart';
import 'package:financial_app/features/recurring_transactions/domain/repositories/recurring_transaction_repository_interface.dart';
import 'package:financial_app/services/logger_service.dart';

class RecurringTransactionController extends ChangeNotifier {
  final RecurringTransactionRepositoryInterface _r;
  RecurringTransactionController({required RecurringTransactionRepositoryInterface repository}) : _r = repository;

  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = false;
  bool _showActiveOnly = true;

  List<Map<String, dynamic>> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get showActiveOnly => _showActiveOnly;

  /// Normalize raw DB maps to clean keys for the UI layer.
  List<Map<String, dynamic>> _normalizeTransactions(List<Map<String, dynamic>> raw) {
    return raw.map((t) {
      return {
        'id': t['transaction_id_232143'] ?? t['id'] ?? '',
        'type': t['type_232143'] ?? t['type'] ?? 'expense',
        'amount': (t['amount_232143'] ?? t['amount'] as num?)?.toDouble() ?? 0.0,
        'description': t['description_232143'] ?? t['description'] ?? '',
        'frequency': t['recurring_pattern_232143'] ?? t['frequency'] ?? 'monthly',
        'is_active': t['is_recurring_232143'] == 1,
        'next_date': t['transaction_date_232143'] ?? t['next_date'] ?? t['date'],
        'category_id': t['category_id_232143'] ?? t['category_id'] ?? '',
        'category_name': t['category_name'] ?? '',
        'transaction_date': t['transaction_date_232143'] ?? t['date'],
      };
    }).toList();
  }

  void toggleFilter() {
    _showActiveOnly = !_showActiveOnly;
    notifyListeners();
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final raw = await _r.getRecurringTransactions(activeOnly: _showActiveOnly);
      _transactions = _normalizeTransactions(raw);
    } catch (e) {
      LoggerService.error('Error loading recurring transactions', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePause(Map<String, dynamic> transaction) async {
    final id = transaction['id']?.toString() ?? transaction['transaction_id_232143']?.toString() ?? '';
    if (id.isEmpty) return;
    final isActive = transaction['is_active'] == true;
    try {
      if (isActive) {
        await _r.pauseRecurringTransaction(id);
      } else {
        await _r.resumeRecurringTransaction(id);
      }
      await loadData();
    } catch (e) {
      LoggerService.error('Error toggling pause', error: e);
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _r.deleteRecurringTransaction(id);
      await loadData();
    } catch (e) {
      LoggerService.error('Error deleting recurring transaction', error: e);
      rethrow;
    }
  }

  Future<void> refresh() async => await loadData();
}
