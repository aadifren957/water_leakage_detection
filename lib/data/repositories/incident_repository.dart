import '../../models/incident_model.dart';
import '../../models/timeline_event_model.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart';
import '../../core/errors/exceptions.dart';
import '../../core/constants/app_constants.dart';
import 'mock_data_store.dart';
import 'worker_repository.dart';
import 'notification_repository.dart';

abstract class IncidentRepository {
  List<IncidentModel> getIncidents();
  Future<List<IncidentModel>> fetchIncidents();
  IncidentModel? getIncidentById(String id);
  List<IncidentModel> getIncidentsForWorker(String workerId);

  Future<IncidentModel> acknowledgeIncident({
    required String incidentId,
    required String officerName,
    required String officerUserId,
  });

  Future<IncidentModel> assignWorker({
    required String incidentId,
    required String workerId,
    required String officerName,
    required String officerUserId,
  });

  Future<IncidentModel> resolveIncident({
    required String incidentId,
    required String workerId,
    required String workerUserId,
    required String workerName,
    String? repairNotes,
  });

  Future<IncidentModel> simulateNewLeakageIncident({
    required String deviceId,
    required String location,
    required String zone,
    required double flowRate,
    required IncidentPriority priority,
  });
}

class MockIncidentRepository implements IncidentRepository {
  final MockDataStore _store;
  final WorkerRepository _workerRepo;
  final NotificationRepository _notificationRepo;

  MockIncidentRepository({
    MockDataStore? store,
    WorkerRepository? workerRepo,
    NotificationRepository? notificationRepo,
  })  : _store = store ?? MockDataStore(),
        _workerRepo = workerRepo ?? MockWorkerRepository(store: store ?? MockDataStore()),
        _notificationRepo = notificationRepo ?? MockNotificationRepository(store: store ?? MockDataStore());

  @override
  List<IncidentModel> getIncidents() {
    return List.unmodifiable(_store.incidents);
  }

  @override
  Future<List<IncidentModel>> fetchIncidents() async {
    return List.unmodifiable(_store.incidents);
  }

  @override
  IncidentModel? getIncidentById(String id) {
    try {
      return _store.incidents.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  List<IncidentModel> getIncidentsForWorker(String workerId) {
    return _store.incidents.where((i) => i.assignedWorkerId == workerId).toList();
  }

  @override
  Future<IncidentModel> acknowledgeIncident({
    required String incidentId,
    required String officerName,
    required String officerUserId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    final index = _store.incidents.indexWhere((i) => i.id == incidentId);
    if (index == -1) {
      throw IncidentNotFoundException(incidentId);
    }

    final incident = _store.incidents[index];

    // Status transition validation
    if (incident.status != IncidentStatus.identified) {
      throw InvalidTransitionException(
        currentStatus: incident.status.displayName,
        attemptedStatus: IncidentStatus.acknowledged.displayName,
        customMessage:
            'Cannot acknowledge incident in "${incident.status.displayName}" status. Only "Identified" incidents can be acknowledged.',
      );
    }

    final now = DateTime.now();
    final newTimeline = List<TimelineEventModel>.from(incident.timeline)
      ..add(
        TimelineEventModel(
          id: 'TLE-${incident.id}-${incident.timeline.length + 1}',
          title: 'Acknowledged by Municipal Officer',
          description:
              'Officer $officerName ($officerUserId) reviewed sensor anomaly and confirmed field dispatch.',
          timestamp: now,
          actorName: officerName,
          actorRole: 'Municipal Officer',
          type: TimelineEventType.acknowledged,
        ),
      );

    final updated = incident.copyWith(
      status: IncidentStatus.acknowledged,
      acknowledgedAt: now,
      acknowledgedBy: officerName,
      timeline: newTimeline,
    );

    _store.incidents[index] = updated;

    // Dispatch notification
    _notificationRepo.addNotification(
      NotificationModel(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        recipientId: officerUserId,
        recipientRole: UserRole.municipalOfficer,
        title: 'Incident Acknowledged',
        message: 'You acknowledged ${incident.id} at ${incident.location}. Ready for worker assignment.',
        incidentId: incident.id,
        timestamp: now,
        isRead: false,
        type: NotificationType.acknowledged,
      ),
    );

    return updated;
  }

  @override
  Future<IncidentModel> assignWorker({
    required String incidentId,
    required String workerId,
    required String officerName,
    required String officerUserId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _store.incidents.indexWhere((i) => i.id == incidentId);
    if (index == -1) {
      throw IncidentNotFoundException(incidentId);
    }

    final incident = _store.incidents[index];

    // Status transition validation
    if (incident.status != IncidentStatus.acknowledged) {
      throw InvalidTransitionException(
        currentStatus: incident.status.displayName,
        attemptedStatus: IncidentStatus.assigned.displayName,
        customMessage:
            'Cannot assign worker to an incident with status "${incident.status.displayName}". The incident must be "Acknowledged" first.',
      );
    }

    final worker = _workerRepo.getWorkerById(workerId);
    if (worker == null) {
      throw AppException('Worker with ID "$workerId" was not found.');
    }

    if (!worker.canAcceptTasks) {
      throw WorkerUnavailableException(
        workerName: worker.name,
        workerId: worker.id,
        reason: '${worker.name} is currently busy (${worker.activeTaskCount}/${worker.maxCapacity} tasks) and cannot take new assignments.',
      );
    }

    // Update worker task count & availability
    _workerRepo.incrementWorkerTaskCount(worker.id);

    final now = DateTime.now();
    final newTimeline = List<TimelineEventModel>.from(incident.timeline)
      ..add(
        TimelineEventModel(
          id: 'TLE-${incident.id}-${incident.timeline.length + 1}',
          title: 'Assigned to ${worker.name}',
          description:
              'Officer $officerName assigned field technician ${worker.name} (${worker.id}) for on-site fault repair.',
          timestamp: now,
          actorName: officerName,
          actorRole: 'Municipal Officer',
          type: TimelineEventType.assigned,
        ),
      );

    final updated = incident.copyWith(
      status: IncidentStatus.assigned,
      assignedWorkerId: worker.id,
      assignedWorkerUserId: worker.userId,
      assignedWorkerName: worker.name,
      assignedAt: now,
      timeline: newTimeline,
    );

    _store.incidents[index] = updated;

    // Send targeted notification to the assigned worker
    _notificationRepo.addNotification(
      NotificationModel(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        recipientId: worker.userId,
        recipientRole: UserRole.fieldWorker,
        title: 'New Task Assigned: ${incident.id}',
        message: 'Officer $officerName assigned you to ${incident.priority.displayName.toUpperCase()} priority leak at ${incident.location}.',
        incidentId: incident.id,
        timestamp: now,
        isRead: false,
        type: NotificationType.workerAssigned,
      ),
    );

    return updated;
  }

  @override
  Future<IncidentModel> resolveIncident({
    required String incidentId,
    required String workerId,
    required String workerUserId,
    required String workerName,
    String? repairNotes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _store.incidents.indexWhere((i) => i.id == incidentId);
    if (index == -1) {
      throw IncidentNotFoundException(incidentId);
    }

    final incident = _store.incidents[index];

    // Status transition validation
    if (incident.status != IncidentStatus.assigned) {
      throw InvalidTransitionException(
        currentStatus: incident.status.displayName,
        attemptedStatus: IncidentStatus.resolved.displayName,
        customMessage:
            'Cannot resolve incident in "${incident.status.displayName}" status. An incident must be "Assigned" before it can be resolved.',
      );
    }

    // Worker authorization validation
    if (incident.assignedWorkerId != workerId && incident.assignedWorkerUserId != workerUserId) {
      throw UnauthorizedActionException(
        'Unauthorized: This task is assigned to "${incident.assignedWorkerName}". You cannot resolve tasks assigned to other technicians.',
      );
    }

    // Decrement worker active task count & restore availability
    _workerRepo.decrementWorkerTaskCount(workerId);

    final now = DateTime.now();
    final defaultNotes = repairNotes?.trim().isNotEmpty == true
        ? repairNotes!.trim()
        : 'Pipe repaired, pressure normalized, and leak successfully sealed.';

    final newTimeline = List<TimelineEventModel>.from(incident.timeline)
      ..add(
        TimelineEventModel(
          id: 'TLE-${incident.id}-${incident.timeline.length + 1}',
          title: 'Marked Resolved by $workerName',
          description: 'Technician $workerName filed repair notes: "$defaultNotes"',
          timestamp: now,
          actorName: workerName,
          actorRole: 'Field Worker',
          type: TimelineEventType.resolved,
        ),
      );

    final updated = incident.copyWith(
      status: IncidentStatus.resolved,
      resolvedAt: now,
      resolvedBy: workerName,
      repairNotes: defaultNotes,
      isLeakageDetected: false,
      isPumpOn: true, // Pump back online after resolution
      timeline: newTimeline,
    );

    _store.incidents[index] = updated;

    // Dispatch notification to Municipal Officer
    _notificationRepo.addNotification(
      NotificationModel(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        recipientId: AppConstants.officerDefaultId,
        recipientRole: UserRole.municipalOfficer,
        title: 'Incident Resolved: ${incident.id}',
        message: '$workerName completed repairs at ${incident.location}. Notes: $defaultNotes',
        incidentId: incident.id,
        timestamp: now,
        isRead: false,
        type: NotificationType.taskResolved,
      ),
    );

    return updated;
  }

  @override
  Future<IncidentModel> simulateNewLeakageIncident({
    required String deviceId,
    required String location,
    required String zone,
    required double flowRate,
    required IncidentPriority priority,
  }) async {
    final now = DateTime.now();
    final newId = 'INC-2026-${(_store.incidents.length + 1).toString().padLeft(3, '0')}';

    final incident = IncidentModel(
      id: newId,
      deviceId: deviceId,
      location: location,
      zone: zone,
      flowRate: flowRate,
      totalVolume: (flowRate * 15.2).clamp(10.0, 500.0),
      isLeakageDetected: true,
      isPumpOn: false,
      status: IncidentStatus.identified,
      priority: priority,
      detectedAt: now,
      timeline: [
        TimelineEventModel(
          id: 'TLE-$newId-1',
          title: 'Leakage Detected',
          description: 'ESP8266 IoT Node $deviceId recorded abnormal flow rate of $flowRate L/min. Automatic safety shutoff active.',
          timestamp: now,
          actorName: 'ESP8266 Telemetry Engine',
          actorRole: 'IoT Sensor Node',
          type: TimelineEventType.detected,
        ),
      ],
    );

    _store.incidents.insert(0, incident);

    // Notify Municipal Officer
    _notificationRepo.addNotification(
      NotificationModel(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        recipientId: AppConstants.officerDefaultId,
        recipientRole: UserRole.municipalOfficer,
        title: 'New Leakage Detected: $newId',
        message: 'Flow anomaly $flowRate L/min detected at $location. Action required.',
        incidentId: newId,
        timestamp: now,
        isRead: false,
        type: NotificationType.leakDetected,
      ),
    );

    return incident;
  }
}
