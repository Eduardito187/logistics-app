import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/driver/presentation/pod_screen.dart'
    show kDigitalSignatureConfirmation, kSignatureEvidenceKind;

import '../support/e2e_app.dart';

/// Flujo 4: tienda — recojo en tienda. El CLIENTE retira su pedido en el
/// mostrador: se escanean los productos, el cliente firma, se saca la foto
/// obligatoria y se registra la entrega (misma prueba de entrega que el
/// chofer, pero la hace el personal de tienda).
void storePickupFlowTests() {
  group('Tienda: recojo del cliente en mostrador', () {
    setUp(e2eSetUp);

    testWidgets(
      'escanea los dos productos, firma, saca la foto obligatoria y entrega',
      (tester) async {
        final photo = writeFakePhoto('pickup.png');
        final h = await pumpE2eApp(
          tester,
          scans: [
            validLabelQr, // producto 1 (QR firmado del vector → vectorUnitId)
            'PROD-2', // producto 2 (código simple)
          ],
          photos: [photo],
        );

        await login(tester, 'tienda@dismac.test');
        await tapVisible(tester, find.text('Recojo en tienda'));

        // La bandeja de recojos muestra el pedido del cliente.
        await pumpUntilFound(tester, find.text('María López'));
        await tapVisible(tester, find.text('María López'));

        // Pantalla del POD de recojo.
        await pumpUntilFound(tester, find.text('Registrar entrega'));
        Finder registerButton() =>
            findButtonWithText<FilledButton>('Registrar entrega');

        // Sin productos escaneados aún: no se puede registrar.
        expect(tester.widget<FilledButton>(registerButton()).onPressed, isNull);

        // --- Escanear los dos productos (un toque por producto) --------------
        Finder scanButton() =>
            findButtonWithText<FilledButton>('Escanear productos');
        await tapVisible(tester, scanButton());
        await settle(tester);
        // Con uno escaneado todavía falta el otro: sigue el botón de escanear.
        await tapVisible(tester, scanButton());
        await settle(tester);

        // Escaneados los dos: el botón pasa a registrar, aún deshabilitado
        // (faltan firma y foto).
        await pumpUntilFound(tester, registerButton());
        expect(scanButton(), findsNothing);
        expect(tester.widget<FilledButton>(registerButton()).onPressed, isNull);
        expect(find.textContaining('la firma del cliente'), findsOneWidget);

        // --- Firma del cliente ----------------------------------------------
        await tapVisible(tester, find.text('Firma del cliente'));
        await pumpUntilFound(tester, find.text('Firmado por el cliente.'));

        // Con firma pero sin foto, todavía no se registra.
        expect(tester.widget<FilledButton>(registerButton()).onPressed, isNull);

        // --- Foto de entrega (obligatoria) ----------------------------------
        await tapVisible(tester, find.text('Tomar foto'));
        await pumpUntilFound(tester, find.text('Volver a tomar'));

        // Listo: firma + foto + productos. Se registra.
        await pumpUntil(
          tester,
          () => tester.widget<FilledButton>(registerButton()).onPressed != null,
          reason: 'Con firma y foto el botón de registrar debería habilitarse',
        );
        await tapVisible(tester, registerButton());
        await settle(tester);

        // --- Backend: la prueba de entrega llegó por la cola offline real ----
        // Un POD por producto (los dos escaneados), del pedido de la tienda.
        expect(h.backend.proofsOfDelivery.length, 2);
        expect(h.backend.proofsOfDelivery.map((p) => p.shipmentId).toSet(), {
          'ship-store-1',
        });
        expect(h.backend.proofsOfDelivery.map((p) => p.unitId).toSet(), {
          vectorUnitId,
          'PROD-2',
        });
        // Confirmación por firma digital y la foto subida (path real del backend).
        for (final pod in h.backend.proofsOfDelivery) {
          expect(pod.confirmation, kDigitalSignatureConfirmation);
          expect(pod.photoPath, startsWith('evidence/pod-'));
        }
        expect(h.backend.delivered, contains('ship-store-1'));

        // La firma viajó como evidencia por la cola de fotos.
        expect(
          h.photos.enqueued.where((e) => e.kind == kSignatureEvidenceKind),
          hasLength(1),
        );

        // Todo despachado: nada pendiente y ningún endpoint inesperado.
        expect(await h.pendingOutbox(), 0);
        expect(h.backend.unhandled, isEmpty);
      },
    );
  });
}
