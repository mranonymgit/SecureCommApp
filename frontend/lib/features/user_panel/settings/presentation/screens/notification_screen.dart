import 'package:flutter/material.dart';

import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../controllers/notification_controller.dart';
import '../widgets/notification_item_tile.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../../admin_panel/presentation/screens/admin_dashboard_screen.dart';
import '../../../../../core/network/api_session.dart';
import '../../../../../core/services/notification_realtime_service.dart';
import '../../../../../core/presentation/app_toast.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final NotificationController _controller;
  final NotificationRealtimeService _realtime = NotificationRealtimeService();

  @override
  void initState() {
    super.initState();
    _controller = NotificationController(
      GetNotificationsUseCase(SettingsRepositoryImpl()),
    )..loadNotifications();
    _realtime.subscribe(_controller.refreshSilently);
  }

  @override
  void dispose() {
    _controller.dispose();
    _realtime.dispose();
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

          if (_controller.loadErrorMessage != null) {
            return Center(
              child: Text(
                _controller.loadErrorMessage!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            );
          }

          if (_controller.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes notificaciones por el momento.',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
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
                onTap: () => _openNotification(item),
                onDelete: () => _deleteNotification(item.id),
                onMarkRead: () => _markNotificationRead(item.id),
                onDismissed: () => _controller.completeDeletion(item.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openNotification(dynamic item) async {
    await _controller.markAsRead(item.id);
    if (!mounted) return;
    final source = (item.sourceType ?? '').toString();
    final destination = source.startsWith('chat')
        ? 3
        : source.startsWith('report')
        ? 4
        : source.startsWith('sos')
        ? 2
        : 1;
    final goToModule = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: Text(item.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cerrar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ver detalle'),
          ),
        ],
      ),
    );
    if (goToModule == true && mounted) {
      final isAdmin = ApiSession.instance.userRole == 'admin';
      final adminDestination = source.startsWith('report')
          ? 4
          : source.startsWith('announcement')
          ? 3
          : 0;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => isAdmin
              ? AdminDashboardScreen(initialIndex: adminDestination)
              : HomeScreen(initialIndex: destination),
        ),
        (route) => false,
      );
    }
  }

  Future<bool> _deleteNotification(String id) async {
    final success = await _controller.deleteNotification(id);
    if (!success && mounted) {
      AppToast.show(
        context,
        _controller.actionErrorMessage ??
            'No se pudo eliminar la notificación.',
        type: AppToastType.error,
      );
    }
    return success;
  }

  Future<bool> _markNotificationRead(String id) async {
    final success = await _controller.markAsRead(id);
    if (!success && mounted) {
      AppToast.show(
        context,
        _controller.actionErrorMessage ?? 'No se pudo marcar como leída.',
        type: AppToastType.error,
      );
    }
    return success;
  }
}
