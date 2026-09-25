import 'package:flutter_test/flutter_test.dart';
import 'package:water_watch/data/repositories/mock_data_store.dart';
import 'package:water_watch/data/repositories/incident_repository.dart';
import 'package:water_watch/data/repositories/worker_repository.dart';
import 'package:water_watch/data/repositories/notification_repository.dart';
import 'package:water_watch/models/incident_model.dart';
import 'package:water_watch/core/errors/exceptions.dart';
import 'package:water_watch/core/constants/app_constants.dart';

void main() {
  group('Incident Lifecycle State Machine Tests', () {
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

    test('Identified -> Acknowledged: Valid transition updates status and timeline', () async {
      final identified = incidentRepo.getIncidents().firstWhere((i) => i.status == IncidentStatus.identified);
      
      final updated = await incidentRepo.acknowledgeIncident(
        incidentId: identified.id,
        officerName: 'Rajesh Varma',
        officerUserId: AppConstants.officerDefaultId,
      );

      expect(updated.status, equals(IncidentStatus.acknowledged));
      expect(updated.acknowledgedBy, equals('Rajesh Varma'));
      expect(updated.acknowledgedAt, isNotNull);
      expect(updated.timeline.last.type.name, equals('acknowledged'));
    });

    test('Invalid Transition: Cannot directly assign an Identified incident without Acknowledging first', () async {
      final identified = incidentRepo.getIncidents().firstWhere((i) => i.status == IncidentStatus.identified);

      expect(
        () async => await incidentRepo.assignWorker(
          incidentId: identified.id,
          workerId: 'WRK-002', // Available worker Priya
          officerName: 'Rajesh Varma',
          officerUserId: AppConstants.officerDefaultId,
        ),
        throwsA(isA<InvalidTransitionException>()),
      );
    });

    test('Invalid Transition: Cannot directly resolve an Identified incident', () async {
      final identified = incidentRepo.getIncidents().firstWhere((i) => i.status == IncidentStatus.identified);

      expect(
        () async => await incidentRepo.resolveIncident(
          incidentId: identified.id,
          workerId: 'WRK-001',
          workerUserId: AppConstants.workerDefaultUserId,
          workerName: 'Rahul Patil',
        ),
        throwsA(isA<InvalidTransitionException>()),
      );
    });

    test('Acknowledged -> Assigned: Valid transition assigns worker and sets timestamp', () async {
      final acknowledged = incidentRepo.getIncidents().firstWhere((i) => i.status == IncidentStatus.acknowledged);

      final updated = await incidentRepo.assignWorker(
        incidentId: acknowledged.id,
        workerId: 'WRK-002', // Priya Sharma
        officerName: 'Rajesh Varma',
        officerUserId: AppConstants.officerDefaultId,
      );

      expect(updated.status, equals(IncidentStatus.assigned));
      expect(updated.assignedWorkerId, equals('WRK-002'));
      expect(updated.assignedWorkerName, equals('Priya Sharma'));
      expect(updated.assignedAt, isNotNull);
      expect(updated.timeline.last.type.name, equals('assigned'));
    });

    test('Assigned -> Resolved: Valid transition completes task and records repair notes', () async {
      // INC-2026-005 is assigned to Rahul Patil (WRK-001)
      final assigned = incidentRepo.getIncidentById('INC-2026-005')!;
      expect(assigned.status, equals(IncidentStatus.assigned));

      final updated = await incidentRepo.resolveIncident(
        incidentId: assigned.id,
        workerId: 'WRK-001',
        workerUserId: AppConstants.workerDefaultUserId,
        workerName: 'Rahul Patil',
        repairNotes: 'Replaced burst seal on 40mm elbow joint.',
      );

      expect(updated.status, equals(IncidentStatus.resolved));
      expect(updated.resolvedBy, equals('Rahul Patil'));
      expect(updated.resolvedAt, isNotNull);
      expect(updated.repairNotes, equals('Replaced burst seal on 40mm elbow joint.'));
      expect(updated.isLeakageDetected, isFalse);
      expect(updated.isPumpOn, isTrue);
    });

    test('Unauthorized Resolution: Worker cannot resolve an incident assigned to another worker', () async {
      // INC-2026-005 is assigned to Rahul Patil (WRK-001)
      expect(
        () async => await incidentRepo.resolveIncident(
          incidentId: 'INC-2026-005',
          workerId: 'WRK-002', // Priya trying to resolve Rahul's task
          workerUserId: 'USR-WRK-002',
          workerName: 'Priya Sharma',
        ),
        throwsA(isA<UnauthorizedActionException>()),
      );
    });
  });
}
