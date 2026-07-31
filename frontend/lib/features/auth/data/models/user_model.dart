import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.username,
    required super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? json['email'] ?? json['full_name'] ?? '')
          .toString(),
      role: (json['role'] ?? 'resident').toString() == 'admin'
          ? UserRole.admin
          : UserRole.resident,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role == UserRole.admin ? 'admin' : 'resident',
    };
  }
}
