/// User Model for CogniFocus-AI
class UserModel {
  final dynamic id;
  final String email;
  final String name;
  final String role; // 'ADMIN' | 'TEACHER'

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isTeacher => role.toUpperCase() == 'TEACHER';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawRole = (json['role'] ?? 'TEACHER').toString().trim().toUpperCase();
    final normalizedRole = rawRole == 'ADMIN' ? 'ADMIN' : 'TEACHER';

    return UserModel(
      id: json['id'] ?? json['user_id'] ?? '',
      email: (json['email'] ?? '').toString().trim(),
      name: (json['name'] ?? json['email'] ?? 'Authorized User').toString(),
      role: normalizedRole,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'name': name, 'role': role};
  }

  @override
  String toString() =>
      'UserModel(id: $id, email: $email, name: $name, role: $role)';
}
