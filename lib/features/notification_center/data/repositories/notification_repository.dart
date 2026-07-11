import 'package:financial_app/services/notification_history_service.dart';
import 'package:financial_app/features/notification_center/domain/repositories/notification_repository_interface.dart';

class NotificationRepository implements NotificationRepositoryInterface {
  final NotificationHistoryService _s;
  NotificationRepository({NotificationHistoryService? service}) : _s = service ?? NotificationHistoryService();
  @override Future<List<dynamic>> getNotifications() => _s.getHistory();
  @override Future<void> markAsRead(String id) => _s.markAsRead(id);
  @override Future<void> clearAll() => _s.clearHistory();
}
