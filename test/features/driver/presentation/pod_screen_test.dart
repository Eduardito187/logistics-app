import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/items3.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/media/photo_picker.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/core/offline/photo_upload_queue.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';
import 'package:logistics_app/features/driver/presentation/pod_screen.dart';
import 'package:logistics_app/features/driver/presentation/signature_pad_screen.dart';

import '../../../support/fake_code_scanner.dart';
import '../../../support/fake_photo_picker.dart';
import '../support/driver_test_support.dart';
import '../support/signature_test_support.dart';
import '../../../support/button_finders.dart';

// Prueba de entrega (POD): producto + confirmación + foto + GPS, offline-first.
//
// El escaneo del producto se inyecta con codeScannerProvider y la etiqueta se
// verifica offline con el vector Ed25519 compartido. La foto de la entrega es
// OBLIGATORIA: se inyecta con photoPickerProvider y se toma antes de registrar
// (los flujos con foto en detalle están en photo_flows_test.dart). La
// confirmación es SOLO la firma del cliente en pantalla (pad con el dedo): no
// hay "QR del cliente" (el cliente no tiene un código). La firma se exporta a
// PNG, se encola como evidencia y el POD lleva el marcador FIRMA_DIGITAL.

/// Cola de fotos falsa: no toca disco ni red; registra lo encolado.
class _NoopPhotoUploadQueue implements PhotoUploadQueue {
  final List<({String kind, Map<String, Object?>? snapshot})> calls = [];

  @override
  Future<void> enqueue({
    required String shipmentId,
    required String filePath,
    required String kind,
    Map<String, Object?>? clientSnapshot,
  }) async {
    calls.add((kind: kind, snapshot: clientSnapshot));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Toma la foto obligatoria de la entrega.
Future<void> _takePhoto(WidgetTester tester) async {
  await tester.tap(find.text('Tomar foto'));
  await tester.pump();
}

List<Object> _overrides(
  FakeCodeScanner fake, {
  FakeOfflineQueue? queue,
  GpsFix? fix,
  FakeSignatureFileStore? signatures,
  // Productos esperados del envío: con `null` se simula "sin señal" (no se
  // sabe el total → no se exige, alcanza ≥1 producto). Con un set, se exige
  // escanearlos todos y se valida la pertenencia.
  Set<String>? units,
}) => [
  codeScannerProvider.overrideWithValue(fake.call),
  labelScannerProvider.overrideWithValue(vectorLabelScanner()),
  locationServiceProvider.overrideWithValue(FakeLocationService(fix: fix)),
  photoPickerProvider.overrideWithValue(FakePhotoPicker(['/tmp/pod.jpg']).call),
  photoUploadQueueProvider.overrideWithValue(_NoopPhotoUploadQueue()),
  driverShipmentUnitsProvider.overrideWith((ref, id) async {
    if (units == null) {
      throw const ApiException(status: 0, title: 'Sin conexión');
    }
    return units;
  }),
  if (queue != null) offlineQueueProvider.overrideWithValue(queue),
  ...signatureOverrides(signatures ?? FakeSignatureFileStore()),
];

/// QR de etiqueta ABIERTA (k:0, sin firma) con un [id] y [order] cualquiera: se
/// valida por pertenencia (orden), no por firma. Sirve para probar el POD con
/// varios productos y el rechazo por orden.
String _openLabelQr(String id, {String order = 'DM-1'}) =>
    '{"v":1,"t":"PKG","k":0,"id":"$id","o":"$order","ln":1,"sku":"SKU-1",'
    '"u":[1,1],"pc":[1,1],"org":"CD01","dst":"C","ts":1700000000,"s":""}';

FilledButton _registerButton(WidgetTester tester) =>
    tester.widget<FilledButton>(
      findButtonWithText<FilledButton>('Registrar entrega'),
    );

void main() {
  testWidgets('render de las tres secciones y botón deshabilitado', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      child: PodScreen(stop: buildStop()),
      overrides: _overrides(FakeCodeScanner([])),
      tall: true,
    );

    expect(find.text('Comprobante de entrega'), findsOneWidget);
    expect(find.text('1. Productos entregados'), findsOneWidget);
    expect(find.text('2. Confirmación del cliente'), findsOneWidget);
    expect(find.text('3. Foto de entrega (obligatoria)'), findsOneWidget);
    expect(find.text('Escaneá cada producto a entregar.'), findsOneWidget);
    expect(_registerButton(tester).onPressed, isNull);
  });

  testWidgets('al entrar calienta el GPS sin esperarlo', (tester) async {
    final location = FakeLocationService();
    await pumpScoped(
      tester,
      child: PodScreen(stop: buildStop()),
      overrides: [
        locationServiceProvider.overrideWithValue(location),
        driverShipmentUnitsProvider.overrideWith((ref, id) async => const {}),
      ],
      tall: true,
    );

    expect(location.prefetchCount, 1);
  });

  testWidgets('confirmación solo por firma: NO existe "QR del cliente"', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      child: PodScreen(stop: buildStop()),
      overrides: _overrides(FakeCodeScanner([])),
      tall: true,
    );

    expect(find.text('Firma en papel (sin QR)'), findsNothing);
    expect(find.text('Firma del cliente'), findsOneWidget);
    // El cliente no tiene un código que escanear: el botón de QR no existe.
    expect(find.text('Escanear QR del cliente'), findsNothing);
    expect(find.text('Pedile al cliente que firme.'), findsOneWidget);
  });

  testWidgets('la firma del cliente fija FIRMA_DIGITAL y muestra la firma', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      child: PodScreen(stop: buildStop()),
      overrides: _overrides(FakeCodeScanner([])),
      tall: true,
    );

    await signOnPad(tester);

    expect(find.byType(SignaturePadScreen), findsNothing);
    expect(find.text('Firmado por el cliente.'), findsOneWidget);
    expect(find.byKey(const ValueKey('signature-preview')), findsOneWidget);
    expect(find.text('Volver a firmar'), findsOneWidget);
    // Falta el producto, así que el botón sigue deshabilitado.
    expect(_registerButton(tester).onPressed, isNull);
  });

  testWidgets(
    'camino feliz: escanea producto, firma el cliente, registra el POD y vuelve',
    (tester) async {
      final fake = FakeCodeScanner([validLabelQr()]);
      final queue = FakeOfflineQueue(SubmitOutcome.sent);
      await pumpPushed(
        tester,
        child: PodScreen(stop: buildStop(shipmentId: 'ship-9')),
        overrides: _overrides(
          fake,
          queue: queue,
          fix: const GpsFix(lat: -17.78, lng: -63.18),
        ),
        tall: true,
      );

      await tester.tap(find.text('Escanear producto'));
      await tester.pumpAndSettle();
      expect(find.text(vectorUnitId), findsOneWidget);
      expect(find.text('Escanear siguiente'), findsOneWidget);

      // Confirmación: el cliente firma (no hay QR del cliente).
      await signOnPad(tester);
      expect(find.text('Firmado por el cliente.'), findsOneWidget);
      expect(fake.requestedTitles, ['Escanear producto']);
      expect(find.byType(ScannerScreen), findsNothing);

      // Sin la foto el botón sigue deshabilitado: es obligatoria.
      expect(_registerButton(tester).onPressed, isNull);
      await _takePhoto(tester);
      expect(_registerButton(tester).onPressed, isNotNull);
      await tester.tap(find.text('Registrar entrega'));
      await tester.pumpAndSettle();

      expect(queue.lastKind, 'recordProofOfDelivery');
      final payload = queue.submissions.single;
      expect(payload['shipment_id'], 'ship-9');
      expect(payload['unit_id'], vectorUnitId);
      expect(payload['confirmation'], 'FIRMA_DIGITAL');
      expect(payload['lat'], -17.78);
      expect(payload['lng'], -63.18);
      expect(
        payload['photo_path'],
        'pendiente',
      ); // foto obligatoria, se sube aparte

      // Feedback y regreso a la pantalla anterior.
      expect(find.text('Registrado.'), findsOneWidget);
      expect(find.byType(PodScreen), findsNothing);
      expect(find.text('Inicio'), findsOneWidget);
    },
  );

  testWidgets(
    'pedido de N productos: exige escanear TODOS y manda un POD por producto',
    (tester) async {
      final queue = FakeOfflineQueue(SubmitOutcome.sent);
      // Envío de 2 productos; etiquetas ABIERTAS (k:0) con ids distintos.
      final fake = FakeCodeScanner([
        _openLabelQr('UNIT-A'),
        _openLabelQr('UNIT-B'),
      ]);
      await pumpPushed(
        tester,
        child: PodScreen(stop: buildStop(shipmentId: 'ship-2u')),
        overrides: _overrides(fake, queue: queue, units: {'UNIT-A', 'UNIT-B'}),
        tall: true,
      );
      await tester.pumpAndSettle();

      // Arranca pidiendo los 2 productos.
      expect(find.text('Escaneá los 2 productos del pedido.'), findsOneWidget);

      // Primer producto: progreso 1 de 2, pero aún NO se puede cerrar (falta
      // uno).
      await tester.tap(find.text('Escanear producto'));
      await tester.pumpAndSettle();
      expect(find.text('Escaneados 1 de 2'), findsOneWidget);
      expect(find.text('UNIT-A'), findsOneWidget);
      await signOnPad(tester);
      await _takePhoto(tester);
      expect(
        _registerButton(tester).onPressed,
        isNull,
        reason: 'con 1 de 2 productos no se puede registrar',
      );

      // Segundo producto: 2 de 2 → ya se puede registrar.
      await tester.tap(find.text('Escanear siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Escaneados 2 de 2'), findsOneWidget);
      expect(find.text('UNIT-B'), findsOneWidget);
      expect(_registerButton(tester).onPressed, isNotNull);

      await tester.tap(find.text('Registrar entrega'));
      await tester.pumpAndSettle();

      // Un POD por producto: 2 envíos, uno por cada unit_id.
      expect(queue.submissions, hasLength(2));
      expect(
        queue.submissions.map((p) => p['unit_id']),
        containsAll(<String>['UNIT-A', 'UNIT-B']),
      );
      expect(find.byType(PodScreen), findsNothing);
    },
  );

  testWidgets('el total de productos sale de unit_ids, no de la cantidad', (
    tester,
  ) async {
    // La cantidad de los ÍTEMS no es la cantidad de productos etiquetados: un
    // ítem con quantity 3 puede salir en 2 etiquetas. Manda `unit_ids` de la
    // parada.
    final queue = FakeOfflineQueue(SubmitOutcome.sent);
    await pumpPushed(
      tester,
      child: PodScreen(
        stop: buildStop(
          items: const [Items3(sku: 'A', name: 'A', quantity: 3)],
          unitIds: const ['u-1', 'u-2'],
        ),
      ),
      overrides: _overrides(FakeCodeScanner([]), queue: queue),
      tall: true,
    );
    await tester.pumpAndSettle();

    // 2 productos (unit_ids), no 3 (quantity).
    expect(find.text('Escaneá los 2 productos del pedido.'), findsOneWidget);
  });

  testWidgets('limita el escaneo al total del pedido (stop.items)', (
    tester,
  ) async {
    // El total sale de los ítems de la parada (siempre viene en la ruta):
    // 2 productos → no se puede escanear un 3º.
    final queue = FakeOfflineQueue(SubmitOutcome.sent);
    final fake = FakeCodeScanner([
      _openLabelQr('U-1'),
      _openLabelQr('U-2'),
      _openLabelQr('U-3'),
    ]);
    await pumpPushed(
      tester,
      child: PodScreen(
        stop: buildStop(
          items: const [
            Items3(sku: 'A', name: 'A', quantity: 1),
            Items3(sku: 'B', name: 'B', quantity: 1),
          ],
        ),
      ),
      overrides: _overrides(fake, queue: queue),
      tall: true,
    );
    await tester.pumpAndSettle();
    expect(find.text('Escaneá los 2 productos del pedido.'), findsOneWidget);

    await tester.tap(find.text('Escanear producto'));
    await tester.pumpAndSettle();
    expect(find.text('Escaneados 1 de 2'), findsOneWidget);

    await tester.tap(find.text('Escanear siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Escaneados 2 de 2'), findsOneWidget);

    // Alcanzado el total del pedido: NO se puede escanear más (botón off).
    final scanBtn = tester.widget<OutlinedButton>(
      findButtonWithText<OutlinedButton>('Escanear siguiente'),
    );
    expect(scanBtn.onPressed, isNull);
  });

  testWidgets(
    'total DESCONOCIDO (backend sin productos): deja seguir escaneando el 2º',
    (tester) async {
      // Regresión: un pedido de 2 productos cuando el backend NO expone
      // cuántos productos son (lista vacía). Antes "Escanear siguiente" se
      // deshabilitaba tras el 1º y no se podía escanear el 2º.
      final queue = FakeOfflineQueue(SubmitOutcome.sent);
      final fake = FakeCodeScanner([_openLabelQr('U-1'), _openLabelQr('U-2')]);
      await pumpPushed(
        tester,
        child: PodScreen(stop: buildStop(shipmentId: 'ship-nuc')),
        // units: null → total desconocido.
        overrides: _overrides(fake, queue: queue),
        tall: true,
      );
      await tester.pumpAndSettle();
      expect(find.text('Escaneá cada producto a entregar.'), findsOneWidget);

      await tester.tap(find.text('Escanear producto'));
      await tester.pumpAndSettle();
      expect(find.text('Escaneados: 1'), findsOneWidget);
      // Con total desconocido, "Escanear siguiente" DEBE seguir habilitado.
      final scanBtn = tester.widget<OutlinedButton>(
        findButtonWithText<OutlinedButton>('Escanear siguiente'),
      );
      expect(scanBtn.onPressed, isNotNull);

      await tester.tap(find.text('Escanear siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Escaneados: 2'), findsOneWidget);
      expect(find.text('U-2'), findsOneWidget);

      await signOnPad(tester);
      await _takePhoto(tester);
      await tester.tap(find.text('Registrar entrega'));
      await tester.pumpAndSettle();
      expect(queue.submissions, hasLength(2));
    },
  );

  testWidgets(
    'no cierra un pedido que no corresponde: rechaza el producto de OTRA orden',
    (tester) async {
      final queue = FakeOfflineQueue(SubmitOutcome.sent);
      final fake = FakeCodeScanner([
        _openLabelQr('U-OTRA', order: 'OTRA-ORDEN'),
        _openLabelQr('U-OK', order: 'DM-1'),
      ]);
      await pumpPushed(
        tester,
        child: PodScreen(stop: buildStop(orderReference: 'DM-1')),
        overrides: _overrides(fake, queue: queue),
        tall: true,
      );
      await tester.pumpAndSettle();

      // Producto de OTRA orden → se rechaza con aviso y NO se agrega.
      await tester.tap(find.text('Escanear producto'));
      await tester.pumpAndSettle();
      expect(find.textContaining('otro pedido'), findsOneWidget);
      expect(find.text('U-OTRA'), findsNothing);

      // Producto de la orden correcta → se acepta.
      await tester.tap(find.text('Escanear producto'));
      await tester.pumpAndSettle();
      expect(find.text('U-OK'), findsOneWidget);
      expect(find.text('Escaneados: 1'), findsOneWidget);
    },
  );

  testWidgets('sin red: queda en cola, avisa y también vuelve', (tester) async {
    final queue = FakeOfflineQueue(SubmitOutcome.queued);
    await pumpPushed(
      tester,
      child: PodScreen(stop: buildStop()),
      overrides: _overrides(FakeCodeScanner([validLabelQr()]), queue: queue),
      tall: true,
    );

    await tester.tap(find.text('Escanear producto'));
    await tester.pumpAndSettle();
    await signOnPad(tester);
    await _takePhoto(tester);
    await tester.tap(find.text('Registrar entrega'));
    await tester.pumpAndSettle();

    final payload = queue.submissions.single;
    expect(payload['confirmation'], 'FIRMA_DIGITAL');
    // Sin fix GPS se registra igual (offline-first) con 0,0.
    expect(payload['lat'], 0);
    expect(payload['lng'], 0);
    expect(find.text('Registrado.'), findsOneWidget);
    expect(find.byType(PodScreen), findsNothing);
  });

  testWidgets('si el registro falla avisa y se queda en la pantalla', (
    tester,
  ) async {
    final queue = FakeOfflineQueue(SubmitOutcome.failed);
    await pumpPushed(
      tester,
      child: PodScreen(stop: buildStop()),
      overrides: _overrides(FakeCodeScanner([validLabelQr()]), queue: queue),
      tall: true,
    );

    await tester.tap(find.text('Escanear producto'));
    await tester.pumpAndSettle();
    await signOnPad(tester);
    await _takePhoto(tester);
    await tester.tap(find.text('Registrar entrega'));
    await tester.pumpAndSettle();

    expect(queue.submissions, hasLength(1));
    expect(
      find.text('No se pudo registrar. Intentá de nuevo.'),
      findsOneWidget,
    );
    expect(find.byType(PodScreen), findsOneWidget);
    // El botón vuelve a quedar habilitado para reintentar.
    expect(_registerButton(tester).onPressed, isNotNull);
  });

  testWidgets('cancelar el escaneo del producto no cambia nada ni envía', (
    tester,
  ) async {
    final queue = FakeOfflineQueue(SubmitOutcome.sent);
    await pumpScoped(
      tester,
      child: PodScreen(stop: buildStop()),
      overrides: _overrides(FakeCodeScanner([null]), queue: queue),
      tall: true,
    );

    await tester.tap(find.text('Escanear producto'));
    await tester.pumpAndSettle();
    await signOnPad(tester);

    expect(find.text('Escaneá cada producto a entregar.'), findsOneWidget);
    expect(find.text('Etiqueta no válida'), findsNothing);
    expect(_registerButton(tester).onPressed, isNull);
    expect(queue.submissions, isEmpty);
  });

  testWidgets('etiqueta con firma inválida: avisa y no toma el producto', (
    tester,
  ) async {
    final queue = FakeOfflineQueue(SubmitOutcome.sent);
    await pumpScoped(
      tester,
      child: PodScreen(stop: buildStop()),
      overrides: _overrides(FakeCodeScanner([tamperedLabelQr()]), queue: queue),
      tall: true,
    );

    await tester.tap(find.text('Escanear producto'));
    await tester.pumpAndSettle();

    expect(find.text('Etiqueta no válida'), findsOneWidget);
    expect(find.text('Escaneá cada producto a entregar.'), findsOneWidget);
    expect(_registerButton(tester).onPressed, isNull);
    expect(queue.submissions, isEmpty);
  });

  group('firma del cliente', () {
    testWidgets('volver del pad sin "Listo" no fija confirmación', (
      tester,
    ) async {
      await pumpScoped(
        tester,
        child: PodScreen(stop: buildStop()),
        overrides: _overrides(FakeCodeScanner([])),
        tall: true,
      );

      await tester.tap(find.text('Firma del cliente'));
      await tester.pumpAndSettle();
      expect(find.byType(SignaturePadScreen), findsOneWidget);
      await drawOnPad(tester);
      // Pantalla de diálogo completo: se cierra con la "X".
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();

      expect(find.byType(SignaturePadScreen), findsNothing);
      expect(find.text('Pedile al cliente que firme.'), findsOneWidget);
    });

    testWidgets('pad: "Listo" y "Borrar" solo se habilitan con trazo', (
      tester,
    ) async {
      await pumpScoped(
        tester,
        child: const SignaturePadScreen(),
        overrides: signatureOverrides(FakeSignatureFileStore()),
      );

      ButtonStyleButton button(String text) => tester.widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text(text),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );

      expect(find.text('Firma del cliente'), findsOneWidget);
      expect(button('Listo').onPressed, isNull);
      expect(button('Borrar').onPressed, isNull);

      await drawOnPad(tester);
      expect(button('Listo').onPressed, isNotNull);
      expect(button('Borrar').onPressed, isNotNull);

      await tester.tap(find.text('Borrar'));
      await tester.pump();
      expect(button('Listo').onPressed, isNull);
    });

    testWidgets('pad: los botones son grandes (uso con guantes)', (
      tester,
    ) async {
      await pumpScoped(
        tester,
        child: const SignaturePadScreen(),
        overrides: signatureOverrides(FakeSignatureFileStore()),
      );

      for (final label in ['Borrar', 'Listo']) {
        final size = tester.getSize(
          find
              .ancestor(
                of: find.text(label),
                matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
              )
              .first,
        );
        expect(size.height, greaterThanOrEqualTo(56));
      }
    });

    testWidgets('pad: exporta un PNG real del trazo', (tester) async {
      Uint8List? result;
      await pumpScoped(
        tester,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async =>
                    result = await captureCustomerSignature(context),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await drawOnPad(tester);
      // La rasterización real necesita el event loop de verdad.
      await tester.runAsync(() async {
        await tester.tap(find.text('Listo'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      // Firma PNG: 89 50 4E 47.
      expect(result!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
      expect(find.byType(SignaturePadScreen), findsNothing);
    });
  });
}
