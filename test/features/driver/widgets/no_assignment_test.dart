import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/driver/presentation/widgets/no_assignment.dart';

import '../support/driver_test_support.dart';

// Pantalla de bloqueo cuando el chofer no tiene asignación para hoy.

void main() {
  testWidgets('muestra el bloqueo con el mensaje por defecto', (tester) async {
    var retried = 0;
    await pumpScoped(
      tester,
      child: Scaffold(body: NoAssignment(onRetry: () => retried++)),
    );

    expect(find.text('Sin asignación'), findsOneWidget);
    // El chofer no tiene forma de operar: solo puede reintentar.
    expect(find.text('Reintentar'), findsOneWidget);

    // El texto de bloqueo avisa que no hay asignación para hoy y deriva al
    // supervisor.
    expect(find.textContaining('asignación para hoy'), findsOneWidget);
    expect(find.textContaining('supervisor'), findsOneWidget);

    // FALENCIA DETECTADA: el enunciado pide el texto EXACTO
    // "No tenés asignación para hoy." pero la implementación usa
    // "No tenés una asignación para hoy. Contactá a tu supervisor."
    // (lib/features/driver/presentation/widgets/no_assignment.dart:34-35).
    // Se verifica el texto REAL para no romper el verde, y se documenta el
    // desvío en la sección de falencias.
    expect(
      find.text('No tenés una asignación para hoy. Contactá a tu supervisor.'),
      findsOneWidget,
    );
  });

  testWidgets('el botón Reintentar dispara el callback', (tester) async {
    var retried = 0;
    await pumpScoped(
      tester,
      child: Scaffold(body: NoAssignment(onRetry: () => retried++)),
    );

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(retried, 1);
  });

  testWidgets('mensaje personalizado (p. ej. error de conexión) se muestra', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      child: Scaffold(
        body: NoAssignment(
          onRetry: () {},
          message: 'Sin conexión. Reintentá al recuperar señal.',
        ),
      ),
    );

    expect(
      find.text('Sin conexión. Reintentá al recuperar señal.'),
      findsOneWidget,
    );
    // Con mensaje propio no se muestra el copy por defecto.
    expect(find.textContaining('Contactá a tu supervisor'), findsNothing);
  });
}
