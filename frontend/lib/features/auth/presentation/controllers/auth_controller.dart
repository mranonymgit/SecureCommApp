import 'package:flutter/material.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';

class AuthController extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;

  AuthController({
    required this.loginUseCase,
    required this.resetPasswordUseCase,
  });

  bool isLoading = false;
  String? errorMessage;

  Future<UserEntity?> login(String username, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final user = await loginUseCase(username, password);
      if (user == null) {
        errorMessage = 'Usuario o contraseña incorrectos.';
      }
      return user;
    } on ApiException catch (e) {
      errorMessage = e.statusCode == 401
          ? 'Correo o contraseña incorrectos.'
          : 'El servidor rechazó el inicio de sesión (${e.statusCode}).';
      debugPrint('Error de inicio de sesión: $e');
      return null;
    } catch (e) {
      errorMessage =
          'No se pudo conectar con la API en ${ApiConfig.baseUrl}. '
          'Verifica SCA_API_URL y que el backend esté disponible.';
      debugPrint('Error de conexión al iniciar sesión: $e');
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String username, String newPassword) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      return await resetPasswordUseCase(username, newPassword);
    } catch (e) {
      errorMessage = 'No se pudo restablecer la contraseña.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
