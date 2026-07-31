import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/domain/entities/user_entity.dart';
import 'package:frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:frontend/features/auth/presentation/screens/forgot_screen.dart';
import 'package:frontend/features/admin_panel/presentation/screens/admin_dashboard_screen.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('Login muestra los controles principales', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(controller: FakeLoginController(null))),
    );

    expect(find.text('Secure Community App'), findsOneWidget);
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });

  testWidgets('Login abre la pantalla de recuperación', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(controller: FakeLoginController(null))),
    );

    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotScreen), findsOneWidget);
  });

  testWidgets('Login con usuario admin navega al dashboard', (tester) async {
    final controller = FakeLoginController(
      const UserEntity(
        id: '1',
        username: 'admin@example.com',
        role: UserRole.admin,
      ),
    );

    await tester.pumpWidget(MaterialApp(home: LoginScreen(controller: controller)));
    await tester.enterText(find.byType(TextField).first, 'admin@example.com');
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.ensureVisible(find.text('Iniciar Sesión'));
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();

    expect(find.byType(AdminDashboardScreen), findsOneWidget);
  });
}
