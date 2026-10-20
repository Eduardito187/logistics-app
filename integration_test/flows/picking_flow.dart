import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../support/e2e_app.dart';

/// Flujo 4: picking — preparar unidad (escaneo EAN) → imprimir (impresora
/// falsa).
void pickingFlowTests() {
  group('Preparador: escanear EAN e imprimir', () {
    setUp(e2eSetUp);

    Future<void> openOrder(WidgetTester tester) async {
      await login(tester, 'preparador@dismac.test');
      await tapVisible(tester, find.text('Pedidos por preparar'));
      await tapVisible(
        tester,
        find.text('Pedido ${FakeBackend.pickingOrderNumber}'),
      );
      await pumpUntilFound(tester, find.text('Unidades (2)'));
    }

    Finder prepareButtons() =>
        findButtonWithText<FilledButton>('Escanear EAN e imprimir');

    testWidgets('asigna carril, prepara las dos unidades, imprime cada '
        'etiqueta y luego el lote firmado', (tester) async {
      final h = await pumpE2eApp(
        tester,
        scans: ['7791234000011', '7791234000028'],
      );
      await openOrder(tester);
      expect(prepareButtons(), findsNWidgets(2));

      // Primera unidad: sin carril asignado, lo pide antes de escanear.
      await tapVisible(tester, prepareButtons());
      await pumpUntilFound(tester, find.text('Carril / vehículo'));
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'CARRIL 3',
      );
      await tapVisible(tester, find.text('Guardar'));
      await pumpUntilFound(tester, find.text('Unidad preparada e impresa.'));
      await pumpUntilFound(tester, find.text('Reimprimir etiqueta'));
      expect(prepareButtons(), findsOneWidget);

      // Segunda unidad: el carril ya está, va directo al escaneo.
      await tapVisible(tester, prepareButtons());
      await pumpUntil(
        tester,
        () => find.text('Reimprimir etiqueta').evaluate().length == 2,
        reason: 'Las dos unidades deberían quedar preparadas',
      );
      expect(prepareButtons(), findsNothing);
      expect(find.text('Carril / vehículo'), findsNothing);

      // Escaneo de EAN (no QR) por unidad.
      expect(h.scanner.requestedTitles, ['Escanear EAN', 'Escanear EAN']);
      expect(h.scanner.requestedFormats.first, contains(BarcodeFormat.ean13));

      // Impresora: el ZPL de cada etiqueta, en orden.
      expect(
        h.printer.printed,
        FakeBackend.pickingLabels.map((l) => l.zpl).toList(),
      );

      // Backend: un escaneo de preparación por unidad, con el carril.
      expect(
        h.backend.preparationScans.map((s) => s.unitId).toList(),
        FakeBackend.pickingLabels.map((l) => l.labelId).toList(),
      );
      expect(h.backend.preparationScans.map((s) => s.vehicleId).toSet(), {
        'CARRIL 3',
      });
      expect(h.backend.preparationScans.map((s) => s.shipmentId).toSet(), {
        FakeBackend.pickingOrderNumber,
      });
      expect(await h.pendingOutbox(), 0);

      // Lote completo: ZPL firmado por el backend.
      await tapVisible(tester, find.text('Imprimir todas las etiquetas'));
      await pumpUntilFound(
        tester,
        find.text('Enviadas 2 etiquetas a la impresora.'),
      );
      expect(h.printer.printed.last, FakeBackend.signedOrderZpl);
      expect(h.backend.unhandled, isEmpty);
    });

    testWidgets('sin impresora: registra la preparación y pide elegir '
        'impresora', (tester) async {
      final h = await pumpE2eApp(
        tester,
        scans: ['7791234000011'],
        printerFails: true,
      );
      await openOrder(tester);

      await tapVisible(tester, prepareButtons());
      await pumpUntilFound(tester, find.text('Carril / vehículo'));
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'CARRIL 1',
      );
      await tapVisible(tester, find.text('Guardar'));

      await pumpUntilFound(
        tester,
        find.text('Seleccioná una impresora en Ajustes.'),
      );
      expect(find.text('Unidad preparada e impresa.'), findsNothing);
      // La preparación igual quedó registrada (offline-first).
      expect(h.backend.preparationScans, hasLength(1));
      expect(find.text('Reimprimir etiqueta'), findsOneWidget);
      expect(h.backend.unhandled, isEmpty);
    });
  });
}
