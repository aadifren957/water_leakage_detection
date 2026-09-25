enum TimelineEventType {
  detected,
  acknowledged,
  assigned,
  resolved;

  String get displayName {
    switch (this) {
      case TimelineEventType.detected:
        return 'Leakage Detected';
      case TimelineEventType.acknowledged:
        return 'Acknowledged';
      case TimelineEventType.assigned:
        return 'Worker Assigned';
      case TimelineEventType.resolved:
        return 'Resolved';
    }
  }
}

class TimelineEventModel {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String? actorName;
  final String? actorRole;
  final TimelineEventType type;

  const TimelineEventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    this.actorName,
    this.actorRole,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'actorName': actorName,
      'actorRole': actorRole,
      'type': type.name,
    };
  }

  factory TimelineEventModel.fromJson(Map<String, dynamic> json) {
    return TimelineEventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      actorName: json['actorName'] as String?,
      actorRole: json['actorRole'] as String?,
      type: TimelineEventType.values.byName(json['type'] as String),
    );
  }
}
