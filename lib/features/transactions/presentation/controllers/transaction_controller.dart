import 'package:flutter/material.dart';
import 'package:financial_app/features/transactions/domain/entities/transaction_entity.dart';
import 'package:financial_app/features/transactions/domain/use_cases/get_transactions_use_case.dart';
import 'package:financial_app/features/transactions/domain/use_cases/create_transaction_use_case.dart';

/// Transaction Controller (Presentation Layer)
class TransactionController extends ChangeNotifier {
  final GetTransactionsUseCase _getTransactionsUseCase;
  final CreateTransactionUseCase _createTransactionUseCase;

  TransactionController(
    this._getTransactionsUseCase,
    this._createTransactionUseCase,
  );

  List<TransactionEntity> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<TransactionEntity> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load transactions
  Future<void> loadTransactions({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await _getTransactionsUseCase(
        type: type,
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create transaction
  Future<bool> createTransaction(TransactionEntity transaction) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _createTransactionUseCase(transaction);
      await loadTransactions(); // Refresh list
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

