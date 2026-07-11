abstract class NotificationRepositoryInterface {
  Future<List<dynamic>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> clearAll();
}
