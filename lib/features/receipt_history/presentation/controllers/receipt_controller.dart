import 'package:flutter/foundation.dart';
import 'package:financial_app/features/receipt_history/data/repositories/receipt_repository.dart';
import 'package:financial_app/services/logger_service.dart';

class ReceiptController extends ChangeNotifier {
  final ReceiptRepository _r;
  ReceiptController({required ReceiptRepository repository})
    : _r = repository;

  List<dynamic> _receipts = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get receipts => _receipts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _receipts = await _r.getReceipts();
    } catch (e) {
      LoggerService.error('Error loading receipts', error: e);
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteReceipt(String id) async {
    try {
      await _r.deleteReceipt(id);
      await loadData();
    } catch (e) {
      LoggerService.error('Error deleting receipt', error: e);
      rethrow;
    }
  }

  Future<void> refresh() async => loadData();
}
