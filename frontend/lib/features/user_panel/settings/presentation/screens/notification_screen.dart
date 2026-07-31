import 'package:flutter/material.dart';

import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../controllers/notification_controller.dart';
import '../widgets/notification_item_tile.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final NotificationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NotificationController(GetNotificationsUseCase(SettingsRepositoryImpl()))..loadNotifications();
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Notificaciones'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.errorMessage != null) {
            return Center(
              child: Text(_controller.errorMessage!, style: TextStyle(color: theme.colorScheme.error)),
            );
          }

          if (_controller.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.38)),
                  const SizedBox(height: 16),
                  Text('No tienes notificaciones por el momento.', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _controller.notifications.length,
            itemBuilder: (context, index) {
              final item = _controller.notifications[index];
              return NotificationItemTile(
                notificacion: {
                  'id': item.id,
                  'titulo': item.title,
                  'mensaje': item.message,
                  'fecha': item.time,
                  'icono': Icons.notifications,
                  'leida': item.isRead,
                },
                onTap: () async => await _controller.markAsRead(item.id),
                onDismissed: (_) async => await _controller.deleteNotification(item.id),
              );
            },
          );
        },
      ),
    );
  }
}
