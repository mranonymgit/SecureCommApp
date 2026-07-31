import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/user_panel/home/domain/entities/news_post.dart';
import 'package:frontend/features/user_panel/reports/domain/usecases/create_report_usecase.dart';
import 'package:frontend/features/user_panel/reports/presentation/controllers/create_report_controller.dart';
import 'package:frontend/features/user_panel/settings/presentation/controllers/notification_controller.dart';

import 'test_helpers.dart';

void main() {
  test('HomeController alterna like y dislike sin dejar estados inválidos', () async {
    final repo = FakeHomeRepository()
      ..posts = [
        const NewsPost(
          id: 'p1',
          adminNombre: 'Admin',
          adminFoto: '',
          fecha: '31/07/2026',
          hora: '10:00',
          titulo: 'Aviso',
          descripcion: 'Texto',
          likes: 1,
          dislikes: 0,
        ),
      ];
    final controller = FakeHomeController(repo);
    await controller.loadNews();

    final error = await controller.toggleLike('p1');
    expect(error, isNull);
    expect(controller.newsPosts.first.userReaction, 'like');

    final error2 = await controller.toggleDislike('p1');
    expect(error2, isNull);
    expect(controller.newsPosts.first.userReaction, 'dislike');
  });

  test('NotificationController marca como leída y elimina notificaciones', () async {
    final repo = FakeSettingsRepositoryImpl();
    final controller = FakeNotificationController(repo);
    await controller.loadNotifications();

    expect(controller.notifications, hasLength(1));
    final marked = await controller.markAsRead('n1');
    expect(marked, isTrue);
    expect(controller.notifications.first.isRead, isTrue);

    final deleted = await controller.deleteNotification('n1');
    expect(deleted, isTrue);
  });

  test('CreateReportController valida datos antes de enviar', () async {
    final controller = CreateReportController(
      CreateReportUseCase(FakeReportsRepository()),
    );

    final success = await controller.sendReport();
    expect(success, isFalse);
    expect(controller.errorMessage, isNotNull);
  });
}
