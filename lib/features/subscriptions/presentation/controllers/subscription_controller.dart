import 'package:flutter/foundation.dart';
import 'package:financial_app/models/subscription_model.dart';
import 'package:financial_app/features/subscriptions/domain/repositories/subscription_repository_interface.dart';
import 'package:financial_app/services/logger_service.dart';

class SubscriptionController extends ChangeNotifier {
  final SubscriptionRepositoryInterface _r;
  SubscriptionController({required SubscriptionRepositoryInterface repository})
    : _r = repository;

  List<SubscriptionModel> _subscriptions = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _activeOnly = true;

  List<SubscriptionModel> get subscriptions => _subscriptions;
  Map<String, dynamic> get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get activeOnly => _activeOnly;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final r = await Future.wait([
        _r.getSubscriptions(activeOnly: _activeOnly),
        _r.getSubscriptionSummary(),
      ]);
      _subscriptions = r[0] as List<SubscriptionModel>;
      _summary = r[1] as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('SubscriptionController.loadData', error: e);
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async => loadData();
  void toggleActiveOnly() {
    _activeOnly = !_activeOnly;
    loadData();
  }

  Future<void> deleteSubscription(String id) async {
    try {
      await _r.deleteSubscription(id);
      await refresh();
    } catch (e) {
      LoggerService.error('SubscriptionController.delete', error: e);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
