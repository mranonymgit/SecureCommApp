import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_text_field.dart';

class ForgotScreen extends StatefulWidget {
  final AuthController? controller;

  const ForgotScreen({super.key, this.controller});

  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  late final AuthController _controller;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureRepeatPassword = true;

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
    _repeatPasswordController.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (_formKey.currentState!.validate()) {
      final success = await _controller.resetPassword(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud enviada con éxito.'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_controller.errorMessage ?? 'Error al procesar solicitud.'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Restablecer Contraseña'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: AuthBackground(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E).withValues(alpha: 0.92),
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  border: Border.all(color: const Color(0xFF333333)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AuthTextField(
                        controller: _usernameController,
                        label: 'Usuario',
                        hint: 'Ingrese su usuario',
                        prefixIcon: Icons.person_outline,
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 16.0),
                      AuthTextField(
                        controller: _passwordController,
                        label: 'Nueva Contraseña',
                        hint: 'Ingrese la nueva contraseña',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Campo obligatorio';
                          if (val.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white54,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      AuthTextField(
                        controller: _repeatPasswordController,
                        label: 'Repita la Contraseña',
                        hint: 'Ingrese nuevamente la contraseña',
                        prefixIcon: Icons.lock_reset_outlined,
                        obscureText: _obscureRepeatPassword,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Campo obligatorio';
                          if (val != _passwordController.text) return 'Las contraseñas no coinciden';
                          return null;
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureRepeatPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white54,
                          ),
                          onPressed: () =>
                              setState(() => _obscureRepeatPassword = !_obscureRepeatPassword),
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      ListenableBuilder(
                        listenable: _controller,
                        builder: (context, _) {
                          return SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _controller.isLoading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryDark,
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _controller.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Enviar solicitud',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
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
        ),
      ),
    );
  }
}