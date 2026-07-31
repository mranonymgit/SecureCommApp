enum UserRole { admin, resident }

class UserEntity {
  final String id;
  final String username;
  final UserRole role;

  const UserEntity({
    required this.id,
    required this.username,
    required this.role,
  });
}
