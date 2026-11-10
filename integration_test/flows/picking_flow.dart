import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../support/e2e_app.dart';

/// Flujo 4: picking — verificar producto (escaneo EAN) → imprimir (impresora
/// falsa). El escaneo de verificación es GLOBAL (un botón del pedido) y cada
/// producto imprime su etiqueta.
void pickingFlowTests() {
  group('Preparador: verificar con escaneo e imprimir', () {
    setUp(e2eSetUp);

    Future<void> openOrder(WidgetTester tester) async {
      await login(tester, 'preparador@dismac.test');
      await tapVisible(tester, find.text('Pedidos por preparar'));
      await tapVisible(
        tester,
        find.text('Pedido ${FakeBackend.pickingOrderNumber}'),
      );
      await pumpUntilFound(tester, find.text('Productos (2)'));
    }

    // El escaneo de verificación es un único botón del pedido (no por ítem).
    Finder verifyButton() => find.text('Verificar productos con escaneo');

    testWidgets('verifica las dos unidades con escaneo (asigna vehículo), '
        'imprime cada etiqueta y luego el lote firmado', (tester) async {
      final h = await pumpE2eApp(
        tester,
        scans: ['7791234000011', '7791234000028'],
      );
      await openOrder(tester);
      // Cada producto ofrece "Imprimir etiqueta" (la lista es perezosa: al menos
      // el primero está construido) y el escaneo es un único botón global.
      expect(
        findButtonWithText<FilledButton>('Imprimir etiqueta'),
        findsWidgets,
      );
      expect(verifyButton(), findsOneWidget);

      // Primer producto: sin vehículo asignado, lo pide antes de escanear.
      await tapVisible(tester, verifyButton());
      await pumpUntilFound(tester, find.text('Vehículo de reparto'));
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'CARRIL 3',
      );
      await tapVisible(tester, find.text('Guardar'));
      await pumpUntilFound(tester, find.text('Producto preparado e impreso.'));
      await pumpUntilFound(tester, find.text('Imprimir de nuevo'));

      // Segundo producto: el vehículo ya está, va directo al escaneo. Cuando las
      // dos unidades quedan preparadas el botón global de verificar desaparece
      // (el ProgressCard está siempre construido; no dependemos de la fila
      // perezosa del segundo producto para comprobarlo).
      await tapVisible(tester, verifyButton());
      await pumpUntil(
        tester,
        () => verifyButton().evaluate().isEmpty,
        reason: 'Las dos unidades deberían quedar preparadas',
      );
      // Ya no quedan productos por verificar.
      expect(verifyButton(), findsNothing);
      expect(find.text('Vehículo de reparto'), findsNothing);

      // Escaneo de EAN (no QR) por producto.
      expect(h.scanner.requestedTitles, [
        'Escanear producto',
        'Escanear producto',
      ]);
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

      await tapVisible(tester, verifyButton());
      await pumpUntilFound(tester, find.text('Vehículo de reparto'));
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
      expect(find.text('Producto preparado e impreso.'), findsNothing);
      // La preparación igual quedó registrada (offline-first).
      expect(h.backend.preparationScans, hasLength(1));
      expect(find.text('Imprimir de nuevo'), findsOneWidget);
      expect(h.backend.unhandled, isEmpty);
    });
  });
}
