import 'package:flutter/foundation.dart';
import 'package:financial_app/features/tags/domain/repositories/tag_repository_interface.dart';
import 'package:financial_app/services/logger_service.dart';

class TagController extends ChangeNotifier {
  final TagRepositoryInterface _r;
  TagController({required TagRepositoryInterface repository}) : _r = repository;

  List<dynamic> _tags = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get tags => _tags;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _tags = await _r.getTags();
    } catch (e) {
      LoggerService.error('Error loading tags', error: e);
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async => loadData();
}
