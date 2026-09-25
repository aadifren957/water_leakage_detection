import '../../models/incident_model.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/errors/exceptions.dart';
import 'incident_repository.dart';

class ApiIncidentRepository implements IncidentRepository {
  final ApiClient _client;
  List<IncidentModel> _cache = [];

  ApiIncidentRepository({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  List<IncidentModel> getIncidents() => List.unmodifiable(_cache);

  @override
  IncidentModel? getIncidentById(String id) {
    try {
      return _cache.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  List<IncidentModel> getIncidentsForWorker(String workerId) {
    return _cache.where((i) => i.assignedWorkerId == workerId || i.assignedWorkerUserId == workerId).toList();
  }

  @override
  Future<List<IncidentModel>> fetchIncidents() async {
    try {
      final res = await _client.get('/incidents');
      if (res is List) {
        _cache = res
            .map((item) => IncidentModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return _cache;
    } on ApiException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      throw AppException('Failed to load incidents: $e');
    }
  }

  @override
  Future<IncidentModel> acknowledgeIncident({
    required String incidentId,
    required String officerName,
    required String officerUserId,
  }) async {
    try {
      final res = await _client.patch('/incidents/$incidentId/acknowledge');
      final updated = IncidentModel.fromJson(res as Map<String, dynamic>);
      
      final index = _cache.indexWhere((i) => i.id == incidentId);
      if (index != -1) {
        _cache[index] = updated;
      } else {
        _cache.add(updated);
      }
      return updated;
    } on ApiException catch (e) {
      if (e.code == 'INVALID_TRANSITION') {
        throw InvalidTransitionException(
          currentStatus: '',
          attemptedStatus: 'Acknowledged',
          customMessage: e.message,
        );
      }
      throw AppException(e.message);
    } catch (e) {
      throw AppException('Acknowledge failed: $e');
    }
  }

  @override
  Future<IncidentModel> assignWorker({
    required String incidentId,
    required String workerId,
    required String officerName,
    required String officerUserId,
  }) async {
    try {
      final res = await _client.patch(
        '/incidents/$incidentId/assign',
        body: {'workerId': workerId},
      );
      final updated = IncidentModel.fromJson(res as Map<String, dynamic>);
      
      final index = _cache.indexWhere((i) => i.id == incidentId);
      if (index != -1) {
        _cache[index] = updated;
      } else {
        _cache.add(updated);
      }
      return updated;
    } on ApiException catch (e) {
      if (e.code == 'WORKER_BUSY') {
        throw WorkerUnavailableException(
          workerName: workerId,
          workerId: workerId,
          reason: e.message,
        );
      }
      if (e.code == 'INVALID_TRANSITION') {
        throw InvalidTransitionException(
          currentStatus: '',
          attemptedStatus: 'Assigned',
          customMessage: e.message,
        );
      }
      throw AppException(e.message);
    } catch (e) {
      throw AppException('Worker assignment failed: $e');
    }
  }

  @override
  Future<IncidentModel> resolveIncident({
    required String incidentId,
    required String workerId,
    required String workerUserId,
    required String workerName,
    String? repairNotes,
  }) async {
    try {
      final res = await _client.patch(
        '/incidents/$incidentId/resolve',
        body: {'repairNotes': repairNotes ?? 'Repaired and pressure normalized.'},
      );
      final updated = IncidentModel.fromJson(res as Map<String, dynamic>);
      
      final index = _cache.indexWhere((i) => i.id == incidentId);
      if (index != -1) {
        _cache[index] = updated;
      } else {
        _cache.add(updated);
      }
      return updated;
    } on ApiException catch (e) {
      if (e.code == 'UNAUTHORIZED_WORKER' || e.statusCode == 403) {
        throw UnauthorizedActionException(e.message);
      }
      if (e.code == 'INVALID_TRANSITION') {
        throw InvalidTransitionException(
          currentStatus: '',
          attemptedStatus: 'Resolved',
          customMessage: e.message,
        );
      }
      throw AppException(e.message);
    } catch (e) {
      throw AppException('Resolution failed: $e');
    }
  }

  @override
  Future<IncidentModel> simulateNewLeakageIncident({
    required String deviceId,
    required String location,
    required String zone,
    required double flowRate,
    required IncidentPriority priority,
  }) async {
    try {
      final res = await _client.post(
        '/incidents',
        body: {
          'title': 'Abnormal Pipeline Flow Anomaly ($flowRate L/min)',
          'description': 'IoT Telemetry node $deviceId recorded flow anomaly of $flowRate L/min.',
          'location': location,
          'zone': zone,
          'deviceId': deviceId,
          'flowRate': flowRate,
          'totalLiters': flowRate * 12.5,
          'leakageDetected': true,
          'pumpStatus': false,
          'severity': priority.name.toUpperCase(),
        },
      );
      final created = IncidentModel.fromJson(res as Map<String, dynamic>);
      _cache.insert(0, created);
      return created;
    } on ApiException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      throw AppException('Failed to create incident: $e');
    }
  }
}
