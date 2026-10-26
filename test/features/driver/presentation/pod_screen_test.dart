import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/media/photo_picker.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/core/offline/photo_upload_queue.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:logistics_app/features/driver/presentation/pod_screen.dart';
import 'package:logistics_app/features/driver/presentation/signature_pad_screen.dart';

import '../../../support/fake_code_scanner.dart';
import '../../../support/fake_photo_picker.dart';
import '../support/driver_test_support.dart';
import '../support/signature_test_support.dart';
import '../../../support/button_finders.dart';

// Prueba de entrega (POD): bulto + confirmación + foto + GPS, offline-first.
//
// El escaneo (bulto y QR del cliente) se inyecta con codeScannerProvider y la
// etiqueta se verifica offline con el vector Ed25519 compartido. La foto de la
// entrega es OBLIGATORIA: se inyecta con photoPickerProvider y se toma antes de
// registrar (los flujos con foto en detalle están en photo_flows_test.dart).
// La confirmación es el QR del cliente o su firma en pantalla (pad con el
// dedo): la firma se exporta a PNG, se encola como evidencia y el POD lleva el
// marcador FIRMA_DIGITAL.

/// Cola de fotos falsa: no toca disco ni red.
class _NoopPhotoUploadQueue implements PhotoUploadQueue {
  @override
  Future<void> enqueue({
    required String shipmentId,
    required String filePath,
    required String kind,
  }) async {}

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
}) => [
  codeScannerProvider.overrideWithValue(fake.call),
  labelScannerProvider.overrideWithValue(vectorLabelScanner()),
  locationServiceProvider.overrideWithValue(FakeLocationService(fix: fix)),
  photoPickerProvider.overrideWithValue(FakePhotoPicker(['/tmp/pod.jpg']).call),
  photoUploadQueueProvider.overrideWithValue(_NoopPhotoUploadQueue()),
  if (queue != null) offlineQueueProvider.overrideWithValue(queue),
  ...signatureOverrides(signatures ?? FakeSignatureFileStore()),
];

FilledButton _registerButton(WidgetTester tester) =>
    tester.widget<FilledButton>(
      findButtonWithText<FilledButton>('Registrar entrega'),
    );

void main() {
  testWidgets('render de las tres secciones y botón deshabilitado', (
    tester,
  ) async {
    await pumpScoped(tester, child: PodScreen(stop: buildStop()), tall: true);

    expect(find.text('Prueba de entrega'), findsOneWidget);
    expect(find.text('1. Bulto entregado'), findsOneWidget);
    expect(find.text('2. Confirmación del cliente'), findsOneWidget);
    expect(find.text('3. Foto de entrega (obligatoria)'), findsOneWidget);
    expect(find.text('Escanea el bulto a entregar.'), findsOneWidget);
    expect(_registerButton(tester).onPressed, isNull);
  });

  testWidgets('al entrar calienta el GPS sin esperarlo', (tester) async {
    final location = FakeLocationService();
    await pumpScoped(
      tester,
      child: PodScreen(stop: buildStop()),
      overrides: [locationServiceProvider.overrideWithValue(location)],
      tall: true,
    );

    expect(location.prefetchCount, 1);
  });

  testWidgets('ya no ofrece la firma en papel: ofrece la firma en pantalla', (
    tester,
  ) async {
    await pumpScoped(tester, child: PodScreen(stop: buildStop()), tall: true);

    expect(find.text('Firma en papel (sin QR)'), findsNothing);
    expect(find.text('Firma del cliente'), findsOneWidget);
    expect(find.text('Escanear QR del cliente'), findsOneWidget);
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
    // Falta el bulto, así que el botón sigue deshabilitado.
    expect(_registerButton(tester).onPressed, isNull);
  });

  testWidgets(
    'camino feliz: escanea bulto y QR del cliente, registra el POD y vuelve',
    (tester) async {
      final fake = FakeCodeScanner([validLabelQr(), 'CONF-123']);
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

      await tester.tap(find.text('Escanear bulto'));
      await tester.pumpAndSettle();
      expect(find.text('Bulto: $vectorUnitId'), findsOneWidget);
      expect(find.text('Reescanear'), findsOneWidget);

      await tester.tap(find.text('Escanear QR del cliente'));
      await tester.pumpAndSettle();
      expect(find.text('Confirmación: CONF-123'), findsOneWidget);
      expect(fake.requestedTitles, ['Escanear bulto', 'QR del cliente']);
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
      expect(payload['confirmation'], 'CONF-123');
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

  testWidgets('sin red: queda en cola, avisa y también vuelve', (tester) async {
    final queue = FakeOfflineQueue(SubmitOutcome.queued);
    await pumpPushed(
      tester,
      child: PodScreen(stop: buildStop()),
      overrides: _overrides(FakeCodeScanner([validLabelQr()]), queue: queue),
      tall: true,
    );

    await tester.tap(find.text('Escanear bulto'));
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
      overrides: _overrides(
        FakeCodeScanner([validLabelQr(), 'CONF-1']),
        queue: queue,
      ),
      tall: true,
    );

    await tester.tap(find.text('Escanear bulto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escanear QR del cliente'));
    await tester.pumpAndSettle();
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

  testWidgets('cancelar el escaneo del bulto no cambia nada ni envía', (
    tester,
  ) async {
    final queue = FakeOfflineQueue(SubmitOutcome.sent);
    await pumpScoped(
      tester,
      child: PodScreen(stop: buildStop()),
      overrides: _overrides(FakeCodeScanner([null]), queue: queue),
      tall: true,
    );

    await tester.tap(find.text('Escanear bulto'));
    await tester.pumpAndSettle();
    await signOnPad(tester);

    expect(find.text('Escanea el bulto a entregar.'), findsOneWidget);
    expect(find.text('Etiqueta no válida'), findsNothing);
    expect(_registerButton(tester).onPressed, isNull);
    expect(queue.submissions, isEmpty);
  });

  testWidgets('cancelar el QR del cliente no fija confirmación', (
    tester,
  ) async {
    final queue = FakeOfflineQueue(SubmitOutcome.sent);
    await pumpScoped(
      tester,
      child: PodScreen(stop: buildStop()),
      overrides: _overrides(
        FakeCodeScanner([validLabelQr(), null]),
        queue: queue,
      ),
      tall: true,
    );

    await tester.tap(find.text('Escanear bulto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escanear QR del cliente'));
    await tester.pumpAndSettle();

    expect(find.text('Bulto: $vectorUnitId'), findsOneWidget);
    expect(
      find.text('Escanea el QR del cliente o pedile que firme.'),
      findsOneWidget,
    );
    expect(_registerButton(tester).onPressed, isNull);
    expect(queue.submissions, isEmpty);
  });

  testWidgets('etiqueta con firma inválida: avisa y no toma el bulto', (
    tester,
  ) async {
    final queue = FakeOfflineQueue(SubmitOutcome.sent);
    await pumpScoped(
      tester,
      child: PodScreen(stop: buildStop()),
      overrides: _overrides(FakeCodeScanner([tamperedLabelQr()]), queue: queue),
      tall: true,
    );

    await tester.tap(find.text('Escanear bulto'));
    await tester.pumpAndSettle();

    expect(find.text('Etiqueta no válida'), findsOneWidget);
    expect(find.text('Escanea el bulto a entregar.'), findsOneWidget);
    expect(_registerButton(tester).onPressed, isNull);
    expect(queue.submissions, isEmpty);
  });

  group('firma del cliente', () {
    testWidgets('el QR reemplaza una firma previa', (tester) async {
      await pumpScoped(
        tester,
        child: PodScreen(stop: buildStop()),
        overrides: _overrides(FakeCodeScanner(['CONF-77'])),
        tall: true,
      );

      await signOnPad(tester);
      expect(find.text('Firmado por el cliente.'), findsOneWidget);

      await tester.tap(find.text('Escanear QR del cliente'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmación: CONF-77'), findsOneWidget);
      expect(find.text('Firmado por el cliente.'), findsNothing);
      expect(find.byKey(const ValueKey('signature-preview')), findsNothing);
      expect(find.text('Firma del cliente'), findsOneWidget);
    });

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
      expect(
        find.text('Escanea el QR del cliente o pedile que firme.'),
        findsOneWidget,
      );
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
