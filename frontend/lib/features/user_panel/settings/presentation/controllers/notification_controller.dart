import 'package:flutter/material.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../data/repositories/settings_repository_impl.dart';

class NotificationController extends ValueNotifier<bool> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final SettingsRepositoryImpl repository;

  List<NotificationItem> notifications = [];
  String? errorMessage;

  NotificationController(
    this.getNotificationsUseCase, {
    SettingsRepositoryImpl? repository,
  }) : repository = repository ?? SettingsRepositoryImpl(),
       super(true);

  Future<void> loadNotifications() async {
    value = true;
    errorMessage = null;
    try {
      notifications = await getNotificationsUseCase();
    } catch (e) {
      errorMessage = 'Error al cargar notificaciones: ${e.toString()}';
    } finally {
      value = false;
    }
  }

  Future<void> markAsRead(String id) async {
    final index = notifications.indexWhere((item) => item.id == id);
    if (index != -1) {
      final original = notifications[index];
      notifications[index] = original.copyWith(isRead: true);
      notifyListeners();
      try {
        await repository.markNotificationRead(id);
      } catch (error) {
        notifications[index] = original;
        errorMessage = 'No se pudo actualizar la notificación.';
        notifyListeners();
      }
    }
  }

  Future<void> deleteNotification(String id) async {
    final index = notifications.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final removed = notifications.removeAt(index);
    notifyListeners();
    try {
      await repository.deleteNotification(id);
    } catch (error) {
      notifications.insert(index, removed);
      errorMessage = 'No se pudo eliminar la notificación.';
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    final unread = notifications
        .where((item) => !item.isRead)
        .toList(growable: false);
    if (unread.isEmpty) return;
    final original = notifications;
    notifications = notifications
        .map((item) => item.copyWith(isRead: true))
        .toList(growable: false);
    notifyListeners();
    try {
      await Future.wait(
        unread.map((item) => repository.markNotificationRead(item.id)),
      );
    } catch (error) {
      notifications = original;
      errorMessage = 'No se pudieron actualizar todas las notificaciones.';
      notifyListeners();
    }
  }
}
