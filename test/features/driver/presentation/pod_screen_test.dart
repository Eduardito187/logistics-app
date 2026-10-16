import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/driver/presentation/pod_screen.dart';

import '../support/driver_test_support.dart';

// Prueba de entrega (POD): bulto + confirmación + foto + GPS, offline-first.
//
// HUECO DE TESTABILIDAD: escanear el bulto abre la cámara (scanVerifiedUnit),
// sin seam inyectable, así que no se puede llegar a habilitar "Registrar
// entrega" en un test de widget. Se cubren el render, la confirmación por firma
// en papel (que sí es testeable) y que el botón arranca deshabilitado.

void main() {
  testWidgets('render de las tres secciones y botón deshabilitado', (
    tester,
  ) async {
    await pumpScoped(tester, child: PodScreen(stop: buildStop()), tall: true);

    expect(find.text('Prueba de entrega'), findsOneWidget);
    expect(find.text('1. Bulto entregado'), findsOneWidget);
    expect(find.text('2. Confirmación del cliente'), findsOneWidget);
    expect(find.text('3. Foto de entrega'), findsOneWidget);
    expect(find.text('Escanea el bulto a entregar.'), findsOneWidget);

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Registrar entrega'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('firma en papel registra la confirmación sin QR', (tester) async {
    await pumpScoped(tester, child: PodScreen(stop: buildStop()), tall: true);

    await tester.tap(find.text('Firma en papel (sin QR)'));
    await tester.pump();

    expect(find.text('Confirmación: FIRMA_PAPEL'), findsOneWidget);

    // Falta el bulto (requiere escaneo), así que el botón sigue deshabilitado.
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Registrar entrega'),
    );
    expect(button.onPressed, isNull);
  });
}
