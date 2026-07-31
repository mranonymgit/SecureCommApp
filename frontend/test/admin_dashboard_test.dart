import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/admin_panel/presentation/screens/admin_dashboard_screen.dart';
import 'package:frontend/features/admin_panel/presentation/widgets/admin_sidebar.dart';
import 'package:frontend/features/admin_panel/presentation/screens/views/admin_overview_view.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('El dashboard de admin renderiza sidebar y overview', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        home: AdminDashboardScreen(
          controller: FakeAdminDashboardController(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(AdminSidebar), findsOneWidget);
    expect(find.byType(AdminOverviewView), findsOneWidget);
    expect(find.text('Residentes'), findsWidgets);
    expect(find.text('Reportes'), findsWidgets);
  });
}
