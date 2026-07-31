import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/user_panel/home/domain/entities/news_post.dart';
import 'package:frontend/features/user_panel/home/presentation/screens/home_screen.dart';
import 'package:frontend/features/user_panel/settings/presentation/screens/notification_screen.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('Home muestra el feed de avisos y la barra inferior', (
    tester,
  ) async {
    final repo = FakeHomeRepository()
      ..posts = [
        const NewsPost(
          id: 'p1',
          adminNombre: 'Admin',
          adminFoto: '',
          fecha: '31/07/2026',
          hora: '10:00',
          titulo: 'Aviso',
          descripcion: 'Texto del aviso',
          likes: 3,
          dislikes: 1,
        ),
      ];

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(controller: FakeHomeController(repo))),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Chat'), findsWidgets);
    expect(find.text('Mapa'), findsWidgets);
  });

  testWidgets('Home renderiza el nav inferior y el acceso a ajustes', (
    tester,
  ) async {
    final repo = FakeHomeRepository()..posts = const [];
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(controller: FakeHomeController(repo))),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NotificationScreen), findsNothing);
    expect(find.text('SOS'), findsWidgets);
  });
}
