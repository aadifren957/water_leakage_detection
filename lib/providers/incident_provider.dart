import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/incident_model.dart';
import '../data/repositories/incident_repository.dart';
import '../data/repositories/api_incident_repository.dart';
import '../core/constants/app_constants.dart';
import 'auth_provider.dart';
import 'worker_provider.dart';
import 'notification_provider.dart';

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return ApiIncidentRepository();
});

class IncidentStats {
  final int totalActive;
  final int identifiedCount;
  final int acknowledgedCount;
  final int assignedCount; // In Progress
  final int resolvedTodayCount;

  const IncidentStats({
    required this.totalActive,
    required this.identifiedCount,
    required this.acknowledgedCount,
    required this.assignedCount,
    required this.resolvedTodayCount,
  });
}

class WorkerStats {
  final int newAssignments; // Assigned today/active
  final int inProgress; // Same as assigned in this 4-stage lifecycle
  final int completed; // Resolved

  const WorkerStats({
    required this.newAssignments,
    required this.inProgress,
    required this.completed,
  });
}

class IncidentsNotifier extends StateNotifier<List<IncidentModel>> {
  final IncidentRepository _repository;
  final Ref _ref;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  IncidentsNotifier(this._repository, this._ref) : super(_repository.getIncidents()) {
    refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    try {
      final incidents = await _repository.fetchIncidents();
      if (!mounted) return;
      state = incidents;
    } catch (_) {
      if (!mounted) return;
      state = _repository.getIncidents();
    } finally {
      if (mounted) {
        _isLoading = false;
      }
    }

    if (!mounted) return;
    try {
      _ref.read(workersListProvider.notifier).refresh();
      _ref.read(userNotificationsProvider.notifier).refresh();
    } catch (_) {}
  }

  Future<void> acknowledge(String incidentId) async {
    final user = _ref.read(authStateProvider).user;
    final officerName = user?.name ?? AppConstants.officerDefaultName;
    final officerUserId = user?.id ?? AppConstants.officerDefaultId;

    await _repository.acknowledgeIncident(
      incidentId: incidentId,
      officerName: officerName,
      officerUserId: officerUserId,
    );

    await refresh();
  }

  Future<void> assignWorker({
    required String incidentId,
    required String workerId,
  }) async {
    final user = _ref.read(authStateProvider).user;
    final officerName = user?.name ?? AppConstants.officerDefaultName;
    final officerUserId = user?.id ?? AppConstants.officerDefaultId;

    await _repository.assignWorker(
      incidentId: incidentId,
      workerId: workerId,
      officerName: officerName,
      officerUserId: officerUserId,
    );

    await refresh();
  }

  Future<void> resolve({
    required String incidentId,
    String? repairNotes,
  }) async {
    final user = _ref.read(authStateProvider).user;
    final workerId = user?.workerId ?? AppConstants.workerDefaultWorkerId;
    final workerUserId = user?.id ?? AppConstants.workerDefaultUserId;
    final workerName = user?.name ?? AppConstants.workerDefaultName;

    await _repository.resolveIncident(
      incidentId: incidentId,
      workerId: workerId,
      workerUserId: workerUserId,
      workerName: workerName,
      repairNotes: repairNotes,
    );

    await refresh();
  }

  Future<void> simulateNewLeak() async {
    await _repository.simulateNewLeakageIncident(
      deviceId: 'WLS-009',
      location: 'South Ring Road, Commercial Boulevard Gate 1',
      zone: 'Commercial South Zone',
      flowRate: 10.80,
      priority: IncidentPriority.high,
    );

    await refresh();
  }
}

final allIncidentsProvider = StateNotifierProvider<IncidentsNotifier, List<IncidentModel>>((ref) {
  final repo = ref.watch(incidentRepositoryProvider);
  return IncidentsNotifier(repo, ref);
});

final incidentStatsProvider = Provider<IncidentStats>((ref) {
  final incidents = ref.watch(allIncidentsProvider);

  final identified = incidents.where((i) => i.status == IncidentStatus.identified).length;
  final acknowledged = incidents.where((i) => i.status == IncidentStatus.acknowledged).length;
  final assigned = incidents.where((i) => i.status == IncidentStatus.assigned).length;
  final resolved = incidents.where((i) => i.status == IncidentStatus.resolved).length;
  final totalActive = identified + acknowledged + assigned;

  return IncidentStats(
    totalActive: totalActive,
    identifiedCount: identified,
    acknowledgedCount: acknowledged,
    assignedCount: assigned,
    resolvedTodayCount: resolved,
  );
});

final workerTasksProvider = Provider<List<IncidentModel>>((ref) {
  final incidents = ref.watch(allIncidentsProvider);
  final user = ref.watch(authStateProvider.select((s) => s.user));

  if (user == null || !user.role.isWorker) {
    return [];
  }

  final targetWorkerId = user.workerId ?? AppConstants.workerDefaultWorkerId;
  final targetUserId = user.id;

  return incidents.where((i) =>
      i.assignedWorkerId == targetWorkerId ||
      i.assignedWorkerUserId == targetUserId ||
      (i.assignedWorkerName != null && i.assignedWorkerName == user.name)).toList();
});

final workerStatsProvider = Provider<WorkerStats>((ref) {
  final tasks = ref.watch(workerTasksProvider);

  final assigned = tasks.where((t) => t.status == IncidentStatus.assigned).length;
  final completed = tasks.where((t) => t.status == IncidentStatus.resolved).length;

  return WorkerStats(
    newAssignments: assigned,
    inProgress: assigned,
    completed: completed,
  );
});
