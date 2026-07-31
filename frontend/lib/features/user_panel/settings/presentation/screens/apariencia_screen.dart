import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/user_panel/settings/domain/entities/app_theme_option.dart';
import 'package:frontend/features/user_panel/settings/presentation/controllers/apariencia_controller.dart';
import 'package:frontend/features/user_panel/settings/presentation/widgets/theme_option_tile.dart';

class AparienciaScreen extends StatefulWidget {
  const AparienciaScreen({super.key});

  @override
  State<AparienciaScreen> createState() => _AparienciaScreenState();
}

class _AparienciaScreenState extends State<AparienciaScreen> {
  late final AparienciaController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AparienciaController()..loadSavedTheme();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apariencia y Accesibilidad'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.remove_red_eye_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Modo de Color para Daltonismo',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Column(
                      children: AppTheme.temas.map((tema) {
                        final bool esSeleccionado = tema.key == _currentThemeKey(_controller.value);
                        return ThemeOptionTile(
                          tema: tema,
                          isSelected: esSeleccionado,
                          onSelect: (nuevoTema) async {
                            if (nuevoTema != null) {
                              await _controller.changeTheme(_themeFromKey(nuevoTema.key));
                              appThemeNotifier.cambiarTema(nuevoTema);
                            }
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _currentThemeKey(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.deuteranopia:
        return 'deuteranopia';
      case AppThemeMode.protanopia:
        return 'protanopia';
      case AppThemeMode.tritanopia:
        return 'tritanopia';
      case AppThemeMode.light:
      case AppThemeMode.dark:
        return 'default';
    }
  }

  AppThemeMode _themeFromKey(String key) {
    switch (key) {
      case 'deuteranopia':
        return AppThemeMode.deuteranopia;
      case 'protanopia':
        return AppThemeMode.protanopia;
      case 'tritanopia':
        return AppThemeMode.tritanopia;
      default:
        return AppThemeMode.dark;
    }
  }
}
