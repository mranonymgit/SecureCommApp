import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/user_panel/maps/presentation/screens/map.dart';
import 'package:frontend/features/user_panel/reports/presentation/screens/create_report_screen.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('El mapa muestra la leyenda y las incidencias', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapaIncidenciasScreen(
            controller: FakeMapsController(FakeMapsRepository()),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Resuelto'), findsOneWidget);
    expect(find.text('En Proceso'), findsOneWidget);
    expect(find.text('Crítico'), findsOneWidget);
  });

  testWidgets('Crear reporte renderiza campos y acciones principales', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CreateReportScreen()),
      ),
    );

    expect(find.text('Crear Reporte Vecinal'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Ubicación del incidente'), findsOneWidget);
    expect(find.text('Adjuntar evidencia'), findsOneWidget);
  });
}
