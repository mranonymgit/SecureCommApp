import 'dart:async';

import 'package:flutter/material.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../data/repositories/settings_repository_impl.dart';

class NotificationController extends ValueNotifier<bool> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final SettingsRepositoryImpl repository;

  List<NotificationItem> notifications = [];
  String? loadErrorMessage;
  String? actionErrorMessage;
  final Set<String> _pendingDeletions = <String>{};

  NotificationController(
    this.getNotificationsUseCase, {
    SettingsRepositoryImpl? repository,
  }) : repository = repository ?? SettingsRepositoryImpl(),
       super(true);

  Future<void> loadNotifications() async {
    value = true;
    loadErrorMessage = null;
    try {
      notifications = await getNotificationsUseCase();
    } catch (e) {
      loadErrorMessage = 'No fue posible cargar las notificaciones.';
    } finally {
      value = false;
    }
  }

  Future<void> refreshSilently() async {
    if (_pendingDeletions.isNotEmpty) return;
    try {
      notifications = await getNotificationsUseCase();
      loadErrorMessage = null;
      notifyListeners();
    } catch (error) {
      debugPrint('Error al sincronizar notificaciones: $error');
    }
  }

  Future<bool> markAsRead(String id) async {
    final index = notifications.indexWhere((item) => item.id == id);
    if (index != -1) {
      final original = notifications[index];
      notifications[index] = original.copyWith(isRead: true);
      notifyListeners();
      try {
        await repository.markNotificationRead(id);
        actionErrorMessage = null;
        return true;
      } catch (error) {
        final rollbackIndex = notifications.indexWhere((item) => item.id == id);
        if (rollbackIndex != -1) notifications[rollbackIndex] = original;
        actionErrorMessage = 'No se pudo actualizar la notificación.';
        notifyListeners();
        return false;
      }
    }
    return false;
  }

  Future<bool> deleteNotification(String id) async {
    if (!notifications.any((item) => item.id == id) ||
        !_pendingDeletions.add(id)) {
      return false;
    }
    try {
      await repository.deleteNotification(id);
      actionErrorMessage = null;
      return true;
    } catch (error) {
      _pendingDeletions.remove(id);
      actionErrorMessage = 'No se pudo eliminar la notificación.';
      notifyListeners();
      return false;
    }
  }

  void completeDeletion(String id) {
    notifications.removeWhere((item) => item.id == id);
    _pendingDeletions.remove(id);
    notifyListeners();
    unawaited(refreshSilently());
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
      actionErrorMessage = null;
    } catch (error) {
      notifications = original;
      actionErrorMessage =
          'No se pudieron actualizar todas las notificaciones.';
      notifyListeners();
    }
  }
}
