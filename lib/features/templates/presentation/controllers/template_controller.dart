import 'package:flutter/foundation.dart';
import 'package:financial_app/features/templates/data/repositories/template_repository.dart';
import 'package:financial_app/models/transaction_template_model.dart';
import 'package:financial_app/services/logger_service.dart';

class TemplateController extends ChangeNotifier {
  final TemplateRepository _r;
  TemplateController({required TemplateRepository repository})
    : _r = repository;

  List<TransactionTemplateModel> _templates = [];
  bool _isLoading = false;
  String? _error;
  List<TransactionTemplateModel> get templates => _templates;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _templates = await _r.getTemplates();
    } catch (e) {
      LoggerService.error('Error loading templates', error: e);
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async => loadData();
}
