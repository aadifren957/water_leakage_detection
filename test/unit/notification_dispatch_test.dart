import 'package:flutter_test/flutter_test.dart';
import 'package:water_watch/data/repositories/mock_data_store.dart';
import 'package:water_watch/data/repositories/incident_repository.dart';
import 'package:water_watch/data/repositories/worker_repository.dart';
import 'package:water_watch/data/repositories/notification_repository.dart';
import 'package:water_watch/models/user_model.dart';
import 'package:water_watch/models/notification_model.dart';
import 'package:water_watch/core/constants/app_constants.dart';

void main() {
  group('Targeted Notification Dispatching & Deduplication Tests', () {
    late MockDataStore store;
    late MockIncidentRepository incidentRepo;
    late MockWorkerRepository workerRepo;
    late MockNotificationRepository notifRepo;

    setUp(() {
      store = MockDataStore();
      store.resetToDefaults();
      workerRepo = MockWorkerRepository(store: store);
      notifRepo = MockNotificationRepository(store: store);
      incidentRepo = MockIncidentRepository(
        store: store,
        workerRepo: workerRepo,
        notificationRepo: notifRepo,
      );
    });

    test('Worker assignment dispatches notification strictly to the assigned worker ID', () async {
      // Assign incident INC-2026-003 to Priya Sharma (WRK-002 -> USR-WRK-002)
      await incidentRepo.assignWorker(
        incidentId: 'INC-2026-003',
        workerId: 'WRK-002',
        officerName: 'Rajesh Varma',
        officerUserId: AppConstants.officerDefaultId,
      );

      final priyaNotifs = notifRepo.getNotificationsForUser('USR-WRK-002', UserRole.fieldWorker);
      expect(priyaNotifs.isNotEmpty, isTrue);

      final latestNotif = priyaNotifs.first;
      expect(latestNotif.recipientId, equals('USR-WRK-002'));
      expect(latestNotif.type, equals(NotificationType.workerAssigned));
      expect(latestNotif.incidentId, equals('INC-2026-003'));

      // Ensure other workers (e.g. Rahul) did not receive this assignment notification
      final rahulNotifs = notifRepo.getNotificationsForUser(AppConstants.workerDefaultUserId, UserRole.fieldWorker);
      final rahulHasPriyaTask = rahulNotifs.any((n) => n.incidentId == 'INC-2026-003');
      expect(rahulHasPriyaTask, isFalse);
    });

    test('Task resolution dispatches notification to the Municipal Officer', () async {
      // Rahul resolves INC-2026-005
      await incidentRepo.resolveIncident(
        incidentId: 'INC-2026-005',
        workerId: 'WRK-001',
        workerUserId: AppConstants.workerDefaultUserId,
        workerName: 'Rahul Patil',
        repairNotes: 'Pipe repaired.',
      );

      final officerNotifs = notifRepo.getNotificationsForUser(AppConstants.officerDefaultId, UserRole.municipalOfficer);
      final resolutionNotif = officerNotifs.firstWhere((n) => n.incidentId == 'INC-2026-005');

      expect(resolutionNotif.recipientId, equals(AppConstants.officerDefaultId));
      expect(resolutionNotif.type, equals(NotificationType.taskResolved));
    });

    test('Notification deduplication prevents duplicate alerts', () {
      final now = DateTime.now();
      final sample = NotificationModel(
        id: 'TEST-NOTIF-1',
        recipientId: 'USR-WRK-001',
        recipientRole: UserRole.fieldWorker,
        title: 'Duplicate Test Alert',
        message: 'Testing deduplication',
        incidentId: 'INC-2026-005',
        timestamp: now,
        type: NotificationType.workerAssigned,
      );

      notifRepo.addNotification(sample);
      final countBefore = notifRepo.getNotificationsForUser('USR-WRK-001', UserRole.fieldWorker).length;

      // Add identical notification with same timestamp & incidentId
      notifRepo.addNotification(sample.copyWith(id: 'TEST-NOTIF-2'));
      final countAfter = notifRepo.getNotificationsForUser('USR-WRK-001', UserRole.fieldWorker).length;

      expect(countAfter, equals(countBefore));
    });
  });
}
