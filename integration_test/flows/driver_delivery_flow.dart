import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../support/e2e_app.dart';

/// Flujo 2: chofer — entrega en curso → escanear bultos → entregar con foto
/// obligatoria → siguiente entrega.
void driverDeliveryFlowTests() {
  group('Chofer: entrega en curso', () {
    setUp(e2eSetUp);

    testWidgets('descarga, prueba de entrega con foto y pasa a la siguiente '
        'parada', (tester) async {
      final photo = writeFakePhoto('pod.png');
      final h = await pumpE2eApp(
        tester,
        scans: [
          validLabelQr, // descarga del bulto en la parada 1
          validLabelQr, // bulto entregado (POD)
          'CLIENTE-QR-123', // QR de confirmación del cliente
        ],
        photos: [photo],
      );

      await login(tester, 'chofer@dismac.test');
      await tapVisible(tester, find.text('Entrega en curso'));

      // Parada 1 de 2.
      await pumpUntilFound(tester, find.text('Entregar pedido'));
      expect(find.text('Parada 1 de 2'), findsOneWidget);
      expect(find.text('En camino a Ana Pérez'), findsOneWidget);

      // --- Escanear bultos (descarga) ---------------------------------------
      await tapVisible(tester, find.text('Escanear bultos'));
      expect(find.text('Escanear bultos · parada 1'), findsOneWidget);
      await tapVisible(tester, find.text('Escanear bulto para descargar'));
      await pumpUntilFound(tester, find.text('1 bulto(s) registrados'));
      expect(find.text(vectorUnitId), findsOneWidget);
      expect(find.text('Registrado'), findsOneWidget);
      await tapVisible(tester, find.byType(BackButton));

      // --- Entregar con foto obligatoria ------------------------------------
      await tapVisible(tester, find.text('Entregar pedido'));
      expect(find.text('Prueba de entrega'), findsOneWidget);

      Finder registerButton() =>
          findButtonWithText<FilledButton>('Registrar entrega');
      bool registerEnabled() =>
          tester.widget<FilledButton>(registerButton()).onPressed != null;

      await tapVisible(tester, find.text('Escanear bulto'));
      expect(find.text('Bulto: $vectorUnitId'), findsOneWidget);
      await tapVisible(tester, find.text('Escanear QR del cliente'));
      expect(find.text('Confirmación: CLIENTE-QR-123'), findsOneWidget);

      // Bulto y confirmación listos, pero sin foto NO se puede registrar.
      expect(registerEnabled(), isFalse);

      await tapVisible(tester, find.text('Tomar foto'));
      expect(find.text('Volver a tomar'), findsOneWidget);
      // Con la vista previa de la foto el botón queda más abajo en la lista.
      await tester.scrollUntilVisible(
        registerButton(),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(registerEnabled(), isTrue);

      await tapVisible(tester, registerButton());

      // Volvió a la entrega: el POD quedó aceptado y se ofrece la siguiente.
      await pumpUntilFound(tester, find.text('Siguiente entrega'));
      await tapVisible(tester, find.text('Siguiente entrega'));

      // --- Siguiente entrega -------------------------------------------------
      await pumpUntilFound(tester, find.text('Parada 2 de 2'));
      expect(find.text('En camino a Carlos Rojas'), findsOneWidget);
      expect(find.text('Entregar pedido'), findsOneWidget);

      // Cámara: escaneos de QR y foto reducida para teléfonos de 1 GB.
      expect(h.scanner.requestedFormats, everyElement([BarcodeFormat.qrCode]));
      expect(h.picker.requests.single.maxWidth, 1600);

      // Backend: descarga y POD llegaron por la cola offline real, con su
      // Idempotency-Key, y la cola quedó vacía (todo sincronizado).
      final unload = h.backend.unloadScans.single;
      expect(unload.shipmentId, 'ship-1');
      expect(unload.unitId, vectorUnitId);
      expect(unload.nodeId, 'stop-1');
      final pod = h.backend.proofsOfDelivery.single;
      expect(pod.shipmentId, 'ship-1');
      expect(pod.unitId, vectorUnitId);
      expect(pod.confirmation, 'CLIENTE-QR-123');
      expect(pod.photoPath, 'pendiente');
      expect(pod.lat, e2eGpsFix.lat);
      final keys = h.backend.requests
          .where((r) => r.path.startsWith('/app/deliveries/'))
          .map((r) => r.idempotencyKey)
          .toList();
      expect(keys, hasLength(2));
      expect(keys.toSet(), hasLength(2));
      expect(keys, everyElement(isNotNull));
      expect(await h.pendingOutbox(), 0);

      // La foto de evidencia quedó en la cola de fotos ligada al envío.
      expect(h.photos.enqueued, [
        (shipmentId: 'ship-1', filePath: photo, kind: 'pod'),
      ]);
      expect(h.backend.unhandled, isEmpty);
    });
  });
}
