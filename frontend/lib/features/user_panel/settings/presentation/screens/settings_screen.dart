import 'package:flutter/material.dart';
import 'package:frontend/features/user_panel/settings/presentation/screens/apariencia_screen.dart';
import 'package:frontend/features/user_panel/settings/presentation/screens/notification_screen.dart';
import 'package:frontend/features/user_panel/settings/presentation/screens/soporte_screen.dart';
import 'package:frontend/features/user_panel/settings/presentation/widgets/settings_menu_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SettingsMenuButton(
            icon: Icons.palette,
            label: 'Apariencia',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AparienciaScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          SettingsMenuButton(
            icon: Icons.notifications,
            label: 'Notificaciones',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          SettingsMenuButton(
            icon: Icons.support_agent,
            label: 'Ayuda y Soporte',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SoporteScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}