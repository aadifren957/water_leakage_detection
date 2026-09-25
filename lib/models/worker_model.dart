class WorkerModel {
  final String id; // e.g. WRK-001
  final String userId; // e.g. USR-WRK-001
  final String name;
  final String email;
  final String phone;
  final String zone;
  final bool isAvailable;
  final int activeTaskCount;
  final int maxCapacity;
  final List<String> skills;

  const WorkerModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.zone,
    this.isAvailable = true,
    this.activeTaskCount = 0,
    this.maxCapacity = 3,
    this.skills = const [],
  });

  bool get isAtCapacity => activeTaskCount >= maxCapacity;
  bool get canAcceptTasks => isAvailable && !isAtCapacity;

  WorkerModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? zone,
    bool? isAvailable,
    int? activeTaskCount,
    int? maxCapacity,
    List<String>? skills,
  }) {
    return WorkerModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      zone: zone ?? this.zone,
      isAvailable: isAvailable ?? this.isAvailable,
      activeTaskCount: activeTaskCount ?? this.activeTaskCount,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      skills: skills ?? this.skills,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'zone': zone,
      'isAvailable': isAvailable,
      'activeTaskCount': activeTaskCount,
      'maxCapacity': maxCapacity,
      'skills': skills,
    };
  }

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      zone: json['zone'] as String,
      isAvailable: json['isAvailable'] as bool? ?? true,
      activeTaskCount: json['activeTaskCount'] as int? ?? 0,
      maxCapacity: json['maxCapacity'] as int? ?? 3,
      skills: (json['skills'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkerModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
