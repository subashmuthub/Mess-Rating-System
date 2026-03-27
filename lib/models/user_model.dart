// User Model - Represents different types of users in the system

enum UserRole { student, faculty, visitor, admin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? department;
  final String? phoneNumber;
  final String? profileImage;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.department,
    this.phoneNumber,
    this.profileImage,
    required this.createdAt,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toString(),
      'department': department,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: UserRole.values.firstWhere((e) => e.toString() == json['role']),
      department: json['department'],
      phoneNumber: json['phoneNumber'],
      profileImage: json['profileImage'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // Copy with method for updates
  UserModel copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? department,
    String? phoneNumber,
    String? profileImage,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt,
    );
  }

  // Helper method to get role name
  String get roleName {
    switch (role) {
      case UserRole.student:
        return 'Student';
      case UserRole.faculty:
        return 'Faculty/Staff';
      case UserRole.visitor:
        return 'Visitor';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
