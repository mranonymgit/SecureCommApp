import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('SCA inicia en la pantalla de autenticacion', (tester) async {
    await tester.pumpWidget(const VecinalApp());

    expect(find.text('Secure Community App'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
  });
}
