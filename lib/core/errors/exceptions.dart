class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

class InvalidTransitionException extends AppException {
  final String currentStatus;
  final String attemptedStatus;

  InvalidTransitionException({
    required this.currentStatus,
    required this.attemptedStatus,
    String? customMessage,
  }) : super(customMessage ??
            'Invalid status transition from "$currentStatus" to "$attemptedStatus".');
}

class WorkerUnavailableException extends AppException {
  final String workerName;
  final String workerId;

  WorkerUnavailableException({
    required this.workerName,
    required this.workerId,
    String? reason,
  }) : super(reason ?? 'Field worker "$workerName" ($workerId) is currently unavailable or at maximum task capacity.');
}

class UnauthorizedActionException extends AppException {
  UnauthorizedActionException(super.message);
}

class IncidentNotFoundException extends AppException {
  final String incidentId;
  IncidentNotFoundException(this.incidentId)
      : super('Incident with ID "$incidentId" was not found.');
}

class AuthException extends AppException {
  AuthException(super.message);
}
