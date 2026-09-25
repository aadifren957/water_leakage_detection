import 'timeline_event_model.dart';

enum IncidentStatus {
  identified,
  acknowledged,
  assigned,
  resolved;

  String get displayName {
    switch (this) {
      case IncidentStatus.identified:
        return 'Identified';
      case IncidentStatus.acknowledged:
        return 'Acknowledged';
      case IncidentStatus.assigned:
        return 'Assigned';
      case IncidentStatus.resolved:
        return 'Resolved';
    }
  }

  bool get isIdentified => this == IncidentStatus.identified;
  bool get isAcknowledged => this == IncidentStatus.acknowledged;
  bool get isAssigned => this == IncidentStatus.assigned;
  bool get isResolved => this == IncidentStatus.resolved;

  bool get isActive => this != IncidentStatus.resolved;
}

enum IncidentPriority {
  low,
  medium,
  high,
  critical;

  String get displayName {
    switch (this) {
      case IncidentPriority.low:
        return 'Low';
      case IncidentPriority.medium:
        return 'Medium';
      case IncidentPriority.high:
        return 'High';
      case IncidentPriority.critical:
        return 'Critical';
    }
  }
}

class IncidentModel {
  final String id;
  final String deviceId;
  final String location;
  final String zone;
  final double flowRate; // L/min
  final double totalVolume; // L
  final bool isLeakageDetected;
  final bool isPumpOn; // Read-only IoT state
  final IncidentStatus status;
  final IncidentPriority priority;
  final DateTime detectedAt;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  final String? assignedWorkerId;
  final String? assignedWorkerUserId;
  final String? assignedWorkerName;
  final DateTime? assignedAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? repairNotes;
  final List<TimelineEventModel> timeline;

  const IncidentModel({
    required this.id,
    required this.deviceId,
    required this.location,
    required this.zone,
    required this.flowRate,
    required this.totalVolume,
    this.isLeakageDetected = true,
    this.isPumpOn = false,
    required this.status,
    required this.priority,
    required this.detectedAt,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.assignedWorkerId,
    this.assignedWorkerUserId,
    this.assignedWorkerName,
    this.assignedAt,
    this.resolvedAt,
    this.resolvedBy,
    this.repairNotes,
    this.timeline = const [],
  });

  Duration? get durationToResolution {
    if (resolvedAt == null) return null;
    return resolvedAt!.difference(detectedAt);
  }

  IncidentModel copyWith({
    String? id,
    String? deviceId,
    String? location,
    String? zone,
    double? flowRate,
    double? totalVolume,
    bool? isLeakageDetected,
    bool? isPumpOn,
    IncidentStatus? status,
    IncidentPriority? priority,
    DateTime? detectedAt,
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
    String? assignedWorkerId,
    String? assignedWorkerUserId,
    String? assignedWorkerName,
    DateTime? assignedAt,
    DateTime? resolvedAt,
    String? resolvedBy,
    String? repairNotes,
    List<TimelineEventModel>? timeline,
  }) {
    return IncidentModel(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      location: location ?? this.location,
      zone: zone ?? this.zone,
      flowRate: flowRate ?? this.flowRate,
      totalVolume: totalVolume ?? this.totalVolume,
      isLeakageDetected: isLeakageDetected ?? this.isLeakageDetected,
      isPumpOn: isPumpOn ?? this.isPumpOn,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      detectedAt: detectedAt ?? this.detectedAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      assignedWorkerId: assignedWorkerId ?? this.assignedWorkerId,
      assignedWorkerUserId: assignedWorkerUserId ?? this.assignedWorkerUserId,
      assignedWorkerName: assignedWorkerName ?? this.assignedWorkerName,
      assignedAt: assignedAt ?? this.assignedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      repairNotes: repairNotes ?? this.repairNotes,
      timeline: timeline ?? this.timeline,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'location': location,
      'zone': zone,
      'flowRate': flowRate,
      'totalVolume': totalVolume,
      'isLeakageDetected': isLeakageDetected,
      'isPumpOn': isPumpOn,
      'status': status.name,
      'priority': priority.name,
      'detectedAt': detectedAt.toIso8601String(),
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      'acknowledgedBy': acknowledgedBy,
      'assignedWorkerId': assignedWorkerId,
      'assignedWorkerUserId': assignedWorkerUserId,
      'assignedWorkerName': assignedWorkerName,
      'assignedAt': assignedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolvedBy': resolvedBy,
      'repairNotes': repairNotes,
      'timeline': timeline.map((e) => e.toJson()).toList(),
    };
  }

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      location: json['location'] as String,
      zone: json['zone'] as String,
      flowRate: (json['flowRate'] as num).toDouble(),
      totalVolume: (json['totalVolume'] as num).toDouble(),
      isLeakageDetected: json['isLeakageDetected'] as bool? ?? true,
      isPumpOn: json['isPumpOn'] as bool? ?? false,
      status: IncidentStatus.values.byName(json['status'] as String),
      priority: IncidentPriority.values.byName(json['priority'] as String),
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      acknowledgedAt: json['acknowledgedAt'] != null
          ? DateTime.parse(json['acknowledgedAt'] as String)
          : null,
      acknowledgedBy: json['acknowledgedBy'] as String?,
      assignedWorkerId: json['assignedWorkerId'] as String?,
      assignedWorkerUserId: json['assignedWorkerUserId'] as String?,
      assignedWorkerName: json['assignedWorkerName'] as String?,
      assignedAt: json['assignedAt'] != null
          ? DateTime.parse(json['assignedAt'] as String)
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      resolvedBy: json['resolvedBy'] as String?,
      repairNotes: json['repairNotes'] as String?,
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((e) => TimelineEventModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncidentModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
