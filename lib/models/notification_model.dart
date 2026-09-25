import 'user_model.dart';

enum NotificationType {
  leakDetected,
  acknowledged,
  workerAssigned,
  taskResolved,
  system;

  String get displayName {
    switch (this) {
      case NotificationType.leakDetected:
        return 'Leak Detected';
      case NotificationType.acknowledged:
        return 'Incident Acknowledged';
      case NotificationType.workerAssigned:
        return 'Task Assigned';
      case NotificationType.taskResolved:
        return 'Incident Resolved';
      case NotificationType.system:
        return 'System Alert';
    }
  }
}

class NotificationModel {
  final String id;
  final String recipientId; // Target User ID e.g. USR-OFF-001 or USR-WRK-001
  final UserRole recipientRole;
  final String title;
  final String message;
  final String? incidentId;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.recipientRole,
    required this.title,
    required this.message,
    this.incidentId,
    required this.timestamp,
    this.isRead = false,
    required this.type,
  });

  NotificationModel copyWith({
    String? id,
    String? recipientId,
    UserRole? recipientRole,
    String? title,
    String? message,
    String? incidentId,
    DateTime? timestamp,
    bool? isRead,
    NotificationType? type,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      recipientRole: recipientRole ?? this.recipientRole,
      title: title ?? this.title,
      message: message ?? this.message,
      incidentId: incidentId ?? this.incidentId,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipientId': recipientId,
      'recipientRole': recipientRole.name,
      'title': title,
      'message': message,
      'incidentId': incidentId,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type.name,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      recipientId: json['recipientId'] as String,
      recipientRole: UserRole.values.byName(json['recipientRole'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      incidentId: json['incidentId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      type: NotificationType.values.byName(json['type'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
