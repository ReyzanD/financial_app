import 'package:flutter/foundation.dart';
import 'package:financial_app/features/templates/domain/repositories/template_repository_interface.dart';
import 'package:financial_app/services/logger_service.dart';

class TemplateController extends ChangeNotifier {
  final TemplateRepositoryInterface _r;
  TemplateController({required TemplateRepositoryInterface repository}) : _r = repository;

  List<dynamic> _templates = []; bool _isLoading = false; String? _error;
  List<dynamic> get templates => _templates; bool get isLoading => _isLoading; String? get error => _error;

  Future<void> loadData() async {
    _isLoading = true; _error = null; notifyListeners();
    try { _templates = await _r.getTemplates(); }
    catch (e) { LoggerService.error('Error loading templates', error: e); _error = e.toString(); }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<void> refresh() async => loadData();
}
