import 'package:flutter/foundation.dart';
import 'package:financial_app/features/notification_center/data/repositories/notification_repository.dart';
import 'package:financial_app/services/logger_service.dart';

class NotificationCenterController extends ChangeNotifier {
  final NotificationRepository _r;
  NotificationCenterController({required NotificationRepository repository}) : _r = repository;

  List<dynamic> _notifications = [];
  bool _isLoading = false;
  List<dynamic> get notifications => _notifications;
  bool get isLoading => _isLoading;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _notifications = await _r.getNotifications();
    } catch (e) {
      LoggerService.error('Error loading notifications', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _r.markAsRead(id);
      await loadData();
    } catch (e) {
      LoggerService.error('Error marking read', error: e);
    }
  }

  Future<void> clearAll() async {
    try {
      await _r.clearAll();
      await loadData();
    } catch (e) {
      LoggerService.error('Error clearing notifications', error: e);
    }
  }
}
