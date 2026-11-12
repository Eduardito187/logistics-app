import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../support/e2e_app.dart';

/// Flujo 2: chofer — entrega en curso → entregar con foto obligatoria →
/// siguiente entrega. La acción es una sola ("Entregar"): el POD ya escanea el
/// producto (el "Escanear" suelto de descarga se quitó del flujo a cliente).
void driverDeliveryFlowTests() {
  group('Chofer: entrega en curso', () {
    setUp(e2eSetUp);

    testWidgets('prueba de entrega con foto y pasa a la siguiente parada', (
      tester,
    ) async {
      final photo = writeFakePhoto('pod.png');
      final h = await pumpE2eApp(
        tester,
        scans: [
          validLabelQr, // producto entregado (POD)
          'CLIENTE-QR-123', // QR de confirmación del cliente
        ],
        photos: [photo],
      );

      await login(tester, 'chofer@dismac.test');
      await tapVisible(tester, find.text('Entrega en curso'));

      // Parada 1 de 2.
      await pumpUntilFound(tester, find.text('Entregar'));
      expect(find.text('Parada 1 de 2'), findsOneWidget);
      expect(find.text('En camino a Ana Pérez'), findsOneWidget);

      // --- Entregar con foto obligatoria ------------------------------------
      await tapVisible(tester, find.text('Entregar'));
      expect(find.text('Comprobante de entrega'), findsOneWidget);

      Finder registerButton() =>
          findButtonWithText<FilledButton>('Registrar entrega');
      bool registerEnabled() =>
          tester.widget<FilledButton>(registerButton()).onPressed != null;

      await tapVisible(tester, find.text('Escanear producto'));
      expect(find.text('Producto: $vectorUnitId'), findsOneWidget);
      await tapVisible(tester, find.text('Escanear QR del cliente'));
      expect(find.text('Confirmación: CLIENTE-QR-123'), findsOneWidget);

      final scroller = find.byType(Scrollable).last;

      // Producto y confirmación listos, pero sin foto NO se puede registrar. El
      // botón está al final de una lista larga (perezosa); se scrollea para
      // construirlo antes de leer su estado.
      await tester.scrollUntilVisible(
        registerButton(),
        150,
        scrollable: scroller,
      );
      expect(registerEnabled(), isFalse);

      // Se vuelve a la foto obligatoria y se toma.
      await tester.scrollUntilVisible(
        find.text('Tomar foto'),
        -150,
        scrollable: scroller,
      );
      await tapVisible(tester, find.text('Tomar foto'));
      expect(find.text('Volver a tomar'), findsOneWidget);

      // Con la foto, el botón de registrar queda habilitado.
      await tester.scrollUntilVisible(
        registerButton(),
        150,
        scrollable: scroller,
      );
      expect(registerEnabled(), isTrue);
      await tapVisible(tester, registerButton());

      // El POD quedó aceptado: la entrega v2 AVANZA sola a la siguiente parada
      // (se resuelve local y no espera a la red, sin un botón intermedio).
      await pumpUntilFound(tester, find.text('Parada 2 de 2'));
      expect(find.text('En camino a Carlos Rojas'), findsOneWidget);
      expect(find.text('Entregar'), findsOneWidget);

      // Cámara: la etiqueta acepta QR + Code128 (Zebra); el QR de confirmación
      // del cliente sigue siendo solo QR. Foto reducida para teléfonos de 1 GB.
      expect(h.scanner.requestedFormats, [
        [BarcodeFormat.qrCode, BarcodeFormat.code128], // etiqueta del producto
        [BarcodeFormat.qrCode], // QR de confirmación del cliente
      ]);
      expect(h.picker.requests.single.maxWidth, 1600);

      // Backend: el POD llegó por la cola offline real, con su Idempotency-Key,
      // y la cola quedó vacía (todo sincronizado).
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
      expect(keys, hasLength(1));
      expect(keys, everyElement(isNotNull));
      expect(await h.pendingOutbox(), 0);

      // La foto de evidencia quedó en la cola de fotos ligada al envío.
      expect(h.photos.enqueued.length, 1);
      expect(h.photos.enqueued.single.shipmentId, 'ship-1');
      expect(h.photos.enqueued.single.filePath, photo);
      expect(h.photos.enqueued.single.kind, 'pod');
      expect(h.backend.unhandled, isEmpty);
    });
  });
}
