import 'package:flutter/foundation.dart';
import 'package:financial_app/models/investment_model.dart';
import 'package:financial_app/features/investments/domain/repositories/investment_repository_interface.dart';
import 'package:financial_app/services/logger_service.dart';

class InvestmentController extends ChangeNotifier {
  final InvestmentRepositoryInterface _r;
  InvestmentController({required InvestmentRepositoryInterface repository}) : _r = repository;

  List<InvestmentModel> _investments = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<InvestmentModel> get investments => _investments;
  Map<String, dynamic> get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadData() async {
    _isLoading = true; _errorMessage = null; notifyListeners();
    try {
      final results = await Future.wait([_r.getInvestments(), _r.getPortfolioSummary()]);
      _investments = results[0] as List<InvestmentModel>;
      _summary = results[1] as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('InvestmentController.loadData', error: e);
      _errorMessage = e.toString();
    } finally { _isLoading = false; notifyListeners(); }
  }

  Future<void> refresh() async => loadData();

  Future<void> deleteInvestment(String id) async {
    try { await _r.deleteInvestment(id); await refresh(); }
    catch (e) { LoggerService.error('InvestmentController.deleteInvestment', error: e); _errorMessage = e.toString(); notifyListeners(); }
  }

  void clearError() { _errorMessage = null; notifyListeners(); }
}
