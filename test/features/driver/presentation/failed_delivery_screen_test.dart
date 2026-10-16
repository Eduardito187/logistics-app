import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/driver/presentation/failed_delivery_screen.dart';

import '../support/driver_test_support.dart';

// Entrega fallida: bulto + motivo tipado + foto opcional + GPS.
//
// HUECO DE TESTABILIDAD: el bulto se obtiene por escaneo de cámara
// (scanVerifiedUnit), sin seam, por lo que no se habilita "Registrar entrega
// fallida" en test. Se cubren el render y los motivos disponibles.

void main() {
  testWidgets('render con los motivos y botón deshabilitado sin bulto', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      child: FailedDeliveryScreen(stop: buildStop()),
      tall: true,
    );

    expect(find.text('Entrega fallida'), findsWidgets);
    expect(find.text('1. Bulto'), findsOneWidget);
    expect(find.text('Escanea el bulto.'), findsOneWidget);

    // Motivos tipados (FailureReason) en español.
    expect(find.text('Cliente ausente'), findsOneWidget);
    expect(find.text('Dirección incorrecta'), findsOneWidget);
    expect(find.text('Pedido rechazado'), findsOneWidget);
    expect(find.text('Producto dañado'), findsOneWidget);
    expect(find.text('Otro motivo'), findsOneWidget);

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Registrar entrega fallida'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('se puede elegir otro motivo', (tester) async {
    await pumpScoped(
      tester,
      child: FailedDeliveryScreen(stop: buildStop()),
      tall: true,
    );

    // Elegir "Producto dañado" no debe fallar (cambia el radio seleccionado).
    await tester.tap(find.text('Producto dañado'));
    await tester.pump();
    expect(find.text('Producto dañado'), findsOneWidget);
  });
}
