import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/store/presentation/controllers/shelf_locations_notifier.dart';

import '../support/e2e_app.dart';

/// Flujo 3: tienda — recepción con la tienda fija del usuario → escanear
/// productos → conciliar.
void storeReceptionFlowTests() {
  group('Tienda: recepción contra manifiesto', () {
    setUp(e2eSetUp);

    testWidgets('abre la recepción, rechaza una etiqueta adulterada, recibe '
        'los productos y concilia', (tester) async {
      final h = await pumpE2eApp(
        tester,
        scans: [
          tamperedLabelQr, // firma inválida: no debe contarse
          validLabelQr, // producto 1 (etiqueta firmada)
          'PROD-2', // producto 2 (código sin firma)
        ],
      );

      await login(tester, 'tienda@dismac.test');
      await tapVisible(tester, find.text('Recepción de mercadería'));

      // La tienda es la del usuario (fija, no se elige).
      await pumpUntilFound(tester, find.text('Tienda Centro'));
      expect(find.text('Tu tienda'), findsOneWidget);
      expect(find.text('ST-01'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);

      // Envío que llega a la tienda.
      await tapVisible(tester, find.text('María López'));
      await pumpUntilFound(tester, find.text('Pedido DM-260012345'));

      // --- Abrir la recepción ------------------------------------------------
      await pumpUntilFound(
        tester,
        find.textContaining('tiene 2 producto(s) esperado(s)'),
      );
      await tapVisible(tester, find.text('Nodo de origen'));
      await tapVisible(tester, find.text('CD Santa Cruz · CD-SCZ').last);
      await tapVisible(
        tester,
        findButtonWithText<FilledButton>('Abrir recepción'),
      );
      await pumpUntilFound(tester, find.text('0/2'));
      expect(h.backend.openedReception?.originNodeId, 'node-cd');
      expect(h.backend.openedReception?.destinationNodeId, 'node-store');
      expect(
        h.backend.openedReception?.expectedUnitIds,
        FakeBackend.storeExpectedUnits,
      );

      Finder scanButton() =>
          findButtonWithText<FilledButton>('Escanear producto');

      // --- Etiqueta adulterada: se avisa y no se recibe ------------------------
      // El aviso "Firma inválida…" se muestra sobre el escáner continuo (overlay
      // que el fake no dibuja), así que se verifica por el feedback del escaneo.
      await tapVisible(tester, scanButton());
      await pumpUntil(
        tester,
        () => h.scanner.continuousMessages.isNotEmpty,
        reason: 'El escaneo de la etiqueta adulterada debería dar feedback',
      );
      expect(
        h.scanner.continuousMessages,
        contains('Etiqueta inválida: editada o falsa'),
      );
      expect(find.text('Ubicación en estante'), findsNothing);
      expect(find.text('0/2'), findsOneWidget);

      // --- Producto 1: firmado; se guarda su ubicación en estante ---------------
      await tapVisible(tester, scanButton());
      await pumpUntilFound(tester, find.text('Ubicación en estante'));
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'PASILLO 3 · B2',
      );
      await tapVisible(tester, find.text('Guardar'));
      await pumpUntilFound(tester, find.text('1/2'));

      // --- Producto 2: código simple; se omite la ubicación --------------------
      await tapVisible(tester, scanButton());
      await pumpUntilFound(tester, find.text('Ubicación en estante'));
      await tapVisible(tester, find.text('Omitir'));
      await pumpUntilFound(tester, find.text('2/2'));

      // --- Conciliar ----------------------------------------------------------
      await tapVisible(tester, find.text('Conciliar y cerrar'));
      expect(
        find.text('Todo coincide con el manifiesto. Se cerrará la recepción.'),
        findsOneWidget,
      );
      await tapVisible(tester, findButtonWithText<FilledButton>('Conciliar'));
      await pumpUntilFound(tester, find.text('Recepción conciliada'));
      expect(scanButton(), findsNothing);

      // Backend: solo los dos productos válidos, por la cola offline real.
      expect(h.backend.receivedUnits, [vectorUnitId, 'PROD-2']);
      expect(
        h.backend.receiveRequests.map((r) => r.destinationNodeId).toSet(),
        {'node-store'},
      );
      expect(h.backend.reconciled, isTrue);
      expect(await h.pendingOutbox(), 0);
      expect(h.container.read(shelfLocationsProvider), {
        vectorUnitId: 'PASILLO 3 · B2',
      });
      expect(h.backend.unhandled, isEmpty);
    });
  });
}
