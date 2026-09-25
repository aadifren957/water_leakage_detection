import '../../models/notification_model.dart';
import '../../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class MockNotifications {
  MockNotifications._();

  static List<NotificationModel> get initialNotifications {
    final now = DateTime.now();

    return [
      // Officer Notifications (USR-OFF-001)
      NotificationModel(
        id: 'NOTIF-001',
        recipientId: AppConstants.officerDefaultId,
        recipientRole: UserRole.municipalOfficer,
        title: 'New Critical Leak Detected!',
        message: 'ESP8266 Node WLS-002 recorded 12.40 L/min surge at Cyber Gateway Avenue, Tech Park.',
        incidentId: 'INC-2026-002',
        timestamp: now.subtract(const Duration(minutes: 10)),
        isRead: false,
        type: NotificationType.leakDetected,
      ),
      NotificationModel(
        id: 'NOTIF-002',
        recipientId: AppConstants.officerDefaultId,
        recipientRole: UserRole.municipalOfficer,
        title: 'New Leakage Detected',
        message: 'ESP8266 Node WLS-001 recorded 8.50 L/min flow anomaly at Sector 4 Main Feeder.',
        incidentId: 'INC-2026-001',
        timestamp: now.subtract(const Duration(minutes: 25)),
        isRead: false,
        type: NotificationType.leakDetected,
      ),
      NotificationModel(
        id: 'NOTIF-003',
        recipientId: AppConstants.officerDefaultId,
        recipientRole: UserRole.municipalOfficer,
        title: 'Incident Resolved by Priya Sharma',
        message: 'INC-2026-007 at Metro Station Plaza has been marked Resolved. Repair notes filed.',
        incidentId: 'INC-2026-007',
        timestamp: now.subtract(const Duration(hours: 3)),
        isRead: true,
        type: NotificationType.taskResolved,
      ),

      // Worker Notifications (USR-WRK-001 - Rahul Patil)
      NotificationModel(
        id: 'NOTIF-004',
        recipientId: AppConstants.workerDefaultUserId,
        recipientRole: UserRole.fieldWorker,
        title: 'New Task Assigned: Green Valley',
        message: 'Officer Rajesh Varma assigned you to high-priority incident INC-2026-005 at Green Valley Block C.',
        incidentId: 'INC-2026-005',
        timestamp: now.subtract(const Duration(hours: 2, minutes: 15)),
        isRead: false,
        type: NotificationType.workerAssigned,
      ),
      NotificationModel(
        id: 'NOTIF-005',
        recipientId: AppConstants.workerDefaultUserId,
        recipientRole: UserRole.fieldWorker,
        title: 'Task Completed & Logged',
        message: 'Your repair log for INC-2026-008 at Railway Colony Junction was recorded successfully.',
        incidentId: 'INC-2026-008',
        timestamp: now.subtract(const Duration(hours: 14)),
        isRead: true,
        type: NotificationType.taskResolved,
      ),
    ];
  }
}
