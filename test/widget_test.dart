import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/app.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';

void main() {
  // Secure storage en memoria: sin mock, el canal de plataforma responde fuera
  // del reloj falso del test y `signOut` (que espera clearToken) queda en vuelo,
  // así que el siguiente "Cerrar sesión" se ignoraba por el guard `_closing`.
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('sin sesión muestra el login', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LogisticsApp()),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(RegExp('DisTrack')), findsWidgets);
    expect(find.text('Ingresar'), findsOneWidget);
  });

  testWidgets('cada rol entra a su propia pantalla de inicio y puede salir', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: LogisticsApp()),
    );
    await tester.pumpAndSettle();

    // El contenedor de Riverpod del árbol ya montado: permite setear la sesión
    // sin pasar por UI de selección de rol (el rol real lo da el backend).
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );

    for (final role in UserRole.values) {
      // devSignIn es un helper de test de la sesión, no UI accesible al usuario.
      container.read(sessionProvider.notifier).devSignIn(role);
      await tester.pumpAndSettle();

      // Navegó fuera del login al inicio del rol: se ve su etiqueta y el cierre.
      expect(find.text('Ingresar'), findsNothing);
      expect(find.text(role.label), findsWidgets);
      expect(find.byTooltip('Cerrar sesión'), findsOneWidget);

      await tester.tap(find.byTooltip('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Ingresar'), findsOneWidget);
    }
  });
}
