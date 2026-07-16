import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/notification_history_service.dart';

class NotificationRepository {
  final NotificationHistoryService _s;
  NotificationRepository({NotificationHistoryService? service}) : _s = service ?? getIt<NotificationHistoryService>();
  Future<List<dynamic>> getNotifications() => _s.getHistory();
  Future<void> markAsRead(String id) => _s.markAsRead(id);
  Future<void> clearAll() => _s.clearHistory();
}
