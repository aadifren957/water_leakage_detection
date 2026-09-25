import '../../models/notification_model.dart';
import '../../models/user_model.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/errors/exceptions.dart';
import 'notification_repository.dart';

class ApiNotificationRepository implements NotificationRepository {
  final ApiClient _client;
  List<NotificationModel> _cache = [];

  ApiNotificationRepository({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  List<NotificationModel> getNotificationsForUser(String userId, UserRole role) {
    return List.unmodifiable(_cache);
  }

  @override
  int getUnreadCount(String userId, UserRole role) {
    return _cache.where((n) => !n.isRead).length;
  }

  @override
  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final res = await _client.get('/notifications');
      if (res is List) {
        _cache = res
            .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return _cache;
    } on ApiException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      throw AppException('Failed to load notifications: $e');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client.patch('/notifications/$notificationId/read');
      final index = _cache.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _cache[index] = _cache[index].copyWith(isRead: true);
      }
    } catch (_) {
      // Optimistic local update
      final index = _cache.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _cache[index] = _cache[index].copyWith(isRead: true);
      }
    }
  }

  @override
  Future<void> markAllAsRead(String userId, UserRole role) async {
    try {
      await _client.patch('/notifications/read-all');
      _cache = _cache.map((n) => n.copyWith(isRead: true)).toList();
    } catch (_) {
      _cache = _cache.map((n) => n.copyWith(isRead: true)).toList();
    }
  }

  @override
  void addNotification(NotificationModel notification) {
    final isDuplicate = _cache.any((n) =>
        n.type == notification.type &&
        n.incidentId == notification.incidentId &&
        notification.incidentId != null);

    if (!isDuplicate) {
      _cache.insert(0, notification);
    }
  }
}
