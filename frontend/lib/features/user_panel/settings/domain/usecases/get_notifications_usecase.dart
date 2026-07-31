import '../entities/notification_item.dart';
import '../repositories/settings_repository.dart';

class GetNotificationsUseCase {
  final SettingsRepository repository;

  GetNotificationsUseCase(this.repository);

  Future<List<NotificationItem>> call() async {
    return await repository.getNotifications();
  }
}
