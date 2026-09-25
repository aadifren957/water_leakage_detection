import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/notification_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/empty_state.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(userNotificationsProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications & Alerts'),
        actions: [
          if (notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () {
                ref.read(userNotificationsProvider.notifier).markAllAsRead();
              },
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Backend Persistence Banner Notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.primaryNavy.withValues(alpha: 0.06),
            child: Row(
              children: const [
                Icon(Icons.mark_email_read_rounded, size: 16, color: AppColors.primaryBlue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Persistent In-App Alerts • Stored in Supabase PostgreSQL',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Notifications List
          Expanded(
            child: notifications.isEmpty
                ? const EmptyStateView(
                    icon: Icons.notifications_none_rounded,
                    title: 'No notifications',
                    message: 'You have no alerts at this time. New leakage incidents and task updates will appear here.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return _buildNotificationCard(context, ref, notif, user?.role.isOfficer ?? true);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notif,
    bool isOfficer,
  ) {
    IconData icon;
    Color color;

    switch (notif.type) {
      case NotificationType.leakDetected:
        icon = Icons.warning_rounded;
        color = AppColors.priorityCritical;
        break;
      case NotificationType.acknowledged:
        icon = Icons.visibility_rounded;
        color = AppColors.statusAcknowledged;
        break;
      case NotificationType.workerAssigned:
        icon = Icons.person_pin_circle_rounded;
        color = AppColors.statusAssigned;
        break;
      case NotificationType.taskResolved:
        icon = Icons.task_alt_rounded;
        color = AppColors.statusResolved;
        break;
      case NotificationType.system:
        icon = Icons.info_outline_rounded;
        color = AppColors.primaryBlue;
        break;
    }

    return InkWell(
      onTap: () {
        ref.read(userNotificationsProvider.notifier).markAsRead(notif.id);
        if (notif.incidentId != null) {
          if (isOfficer) {
            context.push('/officer/incidents/${notif.incidentId}');
          } else {
            context.push('/worker/tasks/${notif.incidentId}');
          }
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : AppColors.statusAcknowledgedBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.isRead ? AppColors.border : AppColors.statusAcknowledgedBorder,
            width: notif.isRead ? 1 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormatter.timeAgo(notif.timestamp),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
