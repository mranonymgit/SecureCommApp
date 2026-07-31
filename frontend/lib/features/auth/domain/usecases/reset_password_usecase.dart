import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;
  ResetPasswordUseCase(this.repository);

  Future<bool> call(String username, String newPassword) async {
    return await repository.resetPassword(username, newPassword);
  }
} 