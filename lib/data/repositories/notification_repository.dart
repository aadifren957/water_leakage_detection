import '../../models/notification_model.dart';
import '../../models/user_model.dart';
import 'mock_data_store.dart';

abstract class NotificationRepository {
  List<NotificationModel> getNotificationsForUser(String userId, UserRole role);
  Future<List<NotificationModel>> fetchNotifications();
  int getUnreadCount(String userId, UserRole role);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId, UserRole role);
  void addNotification(NotificationModel notification);
}

class MockNotificationRepository implements NotificationRepository {
  final MockDataStore _store;

  MockNotificationRepository({MockDataStore? store}) : _store = store ?? MockDataStore();

  @override
  List<NotificationModel> getNotificationsForUser(String userId, UserRole role) {
    return _store.notifications
        .where((n) => n.recipientId == userId || (n.recipientId.isEmpty && n.recipientRole == role))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<List<NotificationModel>> fetchNotifications() async {
    return _store.notifications;
  }

  @override
  int getUnreadCount(String userId, UserRole role) {
    return getNotificationsForUser(userId, role).where((n) => !n.isRead).length;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final index = _store.notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _store.notifications[index] = _store.notifications[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAsRead(String userId, UserRole role) async {
    for (int i = 0; i < _store.notifications.length; i++) {
      final n = _store.notifications[i];
      if (n.recipientId == userId || (n.recipientId.isEmpty && n.recipientRole == role)) {
        _store.notifications[i] = n.copyWith(isRead: true);
      }
    }
  }

  @override
  void addNotification(NotificationModel notification) {
    // Deduplication check: prevent adding same type for same incident if added within last 10 seconds
    final isDuplicate = _store.notifications.any((n) =>
        n.recipientId == notification.recipientId &&
        n.type == notification.type &&
        n.incidentId == notification.incidentId &&
        notification.incidentId != null &&
        notification.timestamp.difference(n.timestamp).inSeconds.abs() < 10);

    if (!isDuplicate) {
      _store.notifications.insert(0, notification);
    }
  }
}
