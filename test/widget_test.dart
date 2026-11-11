import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/app.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';

/// El botón central del shell "respira" en reposo (loop ambiente de
/// AnimatedAppIcon, brief §5/§6), así que `pumpAndSettle` nunca asentaría.
/// Con "reducir movimiento" el ícono queda quieto y el flujo se puede asentar.
void _reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

void main() {
  // Secure storage en memoria: sin mock, el canal de plataforma responde fuera
  // del reloj falso del test y `signOut` (que espera clearToken) queda en vuelo,
  // así que el siguiente "Cerrar sesión" se ignoraba por el guard `_closing`.
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('sin sesión muestra el login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LogisticsApp()));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(RegExp('DisTrack')), findsWidgets);
    expect(find.text('Ingresar'), findsOneWidget);
  });

  testWidgets('al iniciar sesión se descartan los avisos que quedaron del '
      'login (no se filtran al inicio del nuevo usuario)', (tester) async {
    _reduceMotion(tester);
    await tester.pumpWidget(const ProviderScope(child: LogisticsApp()));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );

    // Simula el error de un intento previo en el login (p. ej. un admin sin rol
    // de terreno): el aviso vive en el ScaffoldMessenger RAÍZ de la app.
    const staleError = 'Tu usuario no tiene un rol de terreno asignado.';
    tester
        .firstState<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .showSnackBar(const SnackBar(content: Text(staleError)));
    await tester.pump();
    expect(find.text(staleError), findsOneWidget);

    // Otro usuario (chofer) inicia sesión: el aviso ajeno NO debe seguir visible.
    container.read(sessionProvider.notifier).devSignIn(UserRole.driver);
    await tester.pumpAndSettle();

    expect(find.text('Ingresar'), findsNothing); // ya está en el inicio
    expect(find.text(staleError), findsNothing);
  });

  testWidgets('cada rol entra a su propia pantalla de inicio y puede salir', (
    tester,
  ) async {
    _reduceMotion(tester);
    await tester.pumpWidget(const ProviderScope(child: LogisticsApp()));
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
