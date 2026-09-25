import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/api_notification_repository.dart';
import 'auth_provider.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return ApiNotificationRepository();
});

class NotificationNotifier extends StateNotifier<List<NotificationModel>> {
  final NotificationRepository _repository;
  final UserModel? _user;

  NotificationNotifier(this._repository, this._user) : super([]) {
    refresh();
  }

  Future<void> refresh() async {
    if (_user == null) {
      if (mounted) state = [];
      return;
    }

    try {
      final notifications = await _repository.fetchNotifications();
      if (!mounted) return;
      state = notifications;
    } catch (_) {
      if (!mounted) return;
      state = _repository.getNotificationsForUser(_user.id, _user.role);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _repository.markAsRead(notificationId);
    await refresh();
  }

  Future<void> markAllAsRead() async {
    if (_user == null) return;
    await _repository.markAllAsRead(_user.id, _user.role);
    await refresh();
  }
}

final userNotificationsProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationModel>>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  final user = ref.watch(authStateProvider.select((s) => s.user));
  return NotificationNotifier(repo, user);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(userNotificationsProvider);
  return notifications.where((n) => !n.isRead).length;
});
