enum UserRole {
  municipalOfficer,
  fieldWorker;

  String get displayName {
    switch (this) {
      case UserRole.municipalOfficer:
        return 'Municipal Officer';
      case UserRole.fieldWorker:
        return 'Field Worker';
    }
  }

  bool get isOfficer => this == UserRole.municipalOfficer;
  bool get isWorker => this == UserRole.fieldWorker;
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String department;
  final String? workerId; // WRK-001 for field workers
  final String? phoneNumber;
  final String? zone;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    this.workerId,
    this.phoneNumber,
    this.zone,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? department,
    String? workerId,
    String? phoneNumber,
    String? zone,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      workerId: workerId ?? this.workerId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      zone: zone ?? this.zone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'department': department,
      'workerId': workerId,
      'phoneNumber': phoneNumber,
      'zone': zone,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.byName(json['role'] as String),
      department: json['department'] as String,
      workerId: json['workerId'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      zone: json['zone'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
