import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../admin_panel/presentation/screens/admin_dashboard_screen.dart';
import '../../../user_panel/home/presentation/screens/home_screen.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_text_field.dart';
import 'forgot_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthController? controller;

  const LoginScreen({super.key, this.controller});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthController _controller;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final repo = AuthRepositoryImpl();
    _controller = widget.controller ??
        AuthController(
          loginUseCase: LoginUseCase(repo),
          resetPasswordUseCase: ResetPasswordUseCase(repo),
        );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa usuario y contraseña.', style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    final user = await _controller.login(username, password);

    if (!mounted) return;

    if (user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user.role == UserRole.admin
                ? 'Accediendo como Administrador...'
                : 'Accediendo como Residente...',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Widget targetScreen;
        if (user.role == UserRole.admin) {
          targetScreen = const AdminDashboardScreen();
        } else {
          targetScreen = const HomeScreen();
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => targetScreen),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_controller.errorMessage ?? 'Usuario o contraseña incorrectos.'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                color: Color.fromARGB(64, 0, 0, 0),
                borderRadius: BorderRadius.all(Radius.circular(45)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/OIcon.png', fit: BoxFit.cover),
                  const Text(
                    'Secure Community App',
                    style: TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  AuthTextField(
                    controller: _usernameController,
                    label: 'Usuario',
                    hint: 'Ingrese su usuario',
                    prefixIcon: Icons.person,
                  ),
                  const SizedBox(height: 16.0),
                  AuthTextField(
                    controller: _passwordController,
                    label: 'Contraseña',
                    hint: 'Ingrese su contraseña',
                    prefixIcon: Icons.lock,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white70,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForgotScreen(controller: _controller),
                          ),
                        );
                      },
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(color: AppColors.accent, fontSize: 15.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) {
                      return ElevatedButton(
                        onPressed: _controller.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: AppColors.accent,
                          elevation: 5,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: _controller.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Iniciar Sesión',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17.0,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}