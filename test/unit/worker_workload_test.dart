import 'package:flutter_test/flutter_test.dart';
import 'package:water_watch/data/repositories/mock_data_store.dart';
import 'package:water_watch/data/repositories/incident_repository.dart';
import 'package:water_watch/data/repositories/worker_repository.dart';
import 'package:water_watch/data/repositories/notification_repository.dart';
import 'package:water_watch/core/errors/exceptions.dart';
import 'package:water_watch/core/constants/app_constants.dart';

void main() {
  group('Worker Workload & Availability Tests', () {
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

    test('Assigning worker increments active task count', () async {
      // Priya Sharma WRK-002 starts with 0 active tasks
      final priyaInitial = workerRepo.getWorkerById('WRK-002')!;
      expect(priyaInitial.activeTaskCount, equals(0));
      expect(priyaInitial.canAcceptTasks, isTrue);

      await incidentRepo.assignWorker(
        incidentId: 'INC-2026-003', // Acknowledged incident
        workerId: 'WRK-002',
        officerName: 'Rajesh Varma',
        officerUserId: AppConstants.officerDefaultId,
      );

      final priyaUpdated = workerRepo.getWorkerById('WRK-002')!;
      expect(priyaUpdated.activeTaskCount, equals(1));
    });

    test('Worker reaching maximum capacity is marked unavailable', () async {
      // Rahul Patil WRK-001 has 1 initial task out of 3 capacity
      final rahul = workerRepo.getWorkerById('WRK-001')!;
      expect(rahul.activeTaskCount, equals(1));

      // Manually increment up to 3
      workerRepo.incrementWorkerTaskCount('WRK-001'); // now 2
      workerRepo.incrementWorkerTaskCount('WRK-001'); // now 3

      final rahulFull = workerRepo.getWorkerById('WRK-001')!;
      expect(rahulFull.activeTaskCount, equals(3));
      expect(rahulFull.isAvailable, isFalse);
      expect(rahulFull.canAcceptTasks, isFalse);
    });

    test('Assigning to a busy/at-capacity worker throws WorkerUnavailableException', () async {
      // Neha Kulkarni WRK-004 is initialized at 3/3 capacity (Busy)
      final neha = workerRepo.getWorkerById('WRK-004')!;
      expect(neha.canAcceptTasks, isFalse);

      expect(
        () async => await incidentRepo.assignWorker(
          incidentId: 'INC-2026-003',
          workerId: 'WRK-004',
          officerName: 'Rajesh Varma',
          officerUserId: AppConstants.officerDefaultId,
        ),
        throwsA(isA<WorkerUnavailableException>()),
      );
    });

    test('Resolving task decrements worker active task count and restores availability', () async {
      // Rahul Patil WRK-001 has task INC-2026-005
      final beforeResolve = workerRepo.getWorkerById('WRK-001')!;
      expect(beforeResolve.activeTaskCount, equals(1));

      await incidentRepo.resolveIncident(
        incidentId: 'INC-2026-005',
        workerId: 'WRK-001',
        workerUserId: AppConstants.workerDefaultUserId,
        workerName: 'Rahul Patil',
      );

      final afterResolve = workerRepo.getWorkerById('WRK-001')!;
      expect(afterResolve.activeTaskCount, equals(0));
      expect(afterResolve.isAvailable, isTrue);
    });
  });
}
