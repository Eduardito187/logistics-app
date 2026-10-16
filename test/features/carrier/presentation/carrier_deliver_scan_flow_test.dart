import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/offline/submit_outcome.dart';
import 'package:logistics_app/core/widgets/app_snack.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_deliver_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../support/fake_code_scanner.dart';
import '../carrier_scan_harness.dart';
import '../../../support/button_finders.dart';

// Flujo ENTREGAR: QR firmado del bulto (verificado offline) -> QR de
// confirmación del cliente -> prueba de entrega a la cola -> fila + aviso.
// La cámara se reemplaza con FakeCodeScanner.

Future<void> _tapDeliver(WidgetTester tester) async {
  await tester.tap(findButtonWithText<FilledButton>('Registrar entrega'));
  await tester.pumpAndSettle();
}

/// Superficie visible del aviso (el widget SnackBar incluye su margen).
Finder _snackSurface() => find
    .descendant(of: find.byType(SnackBar), matching: find.byType(Material))
    .first;

void main() {
  testWidgets('bulto válido + confirmación: registra la prueba de entrega', (
    tester,
  ) async {
    final scanner = FakeCodeScanner([validLabelQr(), 'CONF-CLIENTE-1']);
    final pod = FakeRecordProofOfDelivery();
    await pumpCarrierScanScreen(
      tester,
      const CarrierDeliverScreen(),
      scanner: scanner,
      proofOfDelivery: pod,
      fix: const GpsFix(lat: -17.8, lng: -63.2),
    );

    await _tapDeliver(tester);

    expect(scanner.requestedTitles, [
      'Entregar bulto',
      'Confirmación del cliente',
    ]);
    expect(scanner.requestedFormats, [
      [BarcodeFormat.qrCode],
      [BarcodeFormat.qrCode],
    ]);
    final request = pod.requests.single;
    expect(request.shipmentId, vectorOrder);
    expect(request.unitId, vectorUnitId);
    expect(request.confirmation, 'CONF-CLIENTE-1');
    expect(request.lat, -17.8);
    expect(request.lng, -63.2);
    expect(pod.labels.single, 'Entrega · $vectorSku');

    expect(find.text('Sin entregas registradas'), findsNothing);
    expect(find.text(vectorSku), findsOneWidget);
    expect(find.text('Enviado'), findsOneWidget);
    expect(find.text('Registrado.'), findsOneWidget);
  });

  testWidgets('encolado offline: se ve igual que enviado (offline invisible)', (
    tester,
  ) async {
    await pumpCarrierScanScreen(
      tester,
      const CarrierDeliverScreen(),
      scanner: FakeCodeScanner([validLabelQr(), 'CONF']),
      proofOfDelivery: FakeRecordProofOfDelivery(SubmitOutcome.queued),
    );

    await _tapDeliver(tester);

    expect(find.text('Enviado'), findsOneWidget);
    expect(find.text('Pendiente'), findsNothing);
    expect(find.text('Registrado.'), findsOneWidget);
  });

  testWidgets('envío fallido: fila "Error" y aviso de revisar sincronización', (
    tester,
  ) async {
    await pumpCarrierScanScreen(
      tester,
      const CarrierDeliverScreen(),
      scanner: FakeCodeScanner([validLabelQr(), 'CONF']),
      proofOfDelivery: FakeRecordProofOfDelivery(SubmitOutcome.failed),
    );

    await _tapDeliver(tester);

    expect(find.text('Error'), findsOneWidget);
    expect(
      find.text('No se pudo registrar. Intentá de nuevo.'),
      findsOneWidget,
    );
  });

  testWidgets('cancelar el escaneo del bulto no pide la confirmación', (
    tester,
  ) async {
    final scanner = FakeCodeScanner([null, 'CONF']);
    final pod = FakeRecordProofOfDelivery();
    await pumpCarrierScanScreen(
      tester,
      const CarrierDeliverScreen(),
      scanner: scanner,
      proofOfDelivery: pod,
    );

    await _tapDeliver(tester);

    expect(scanner.requestedTitles, ['Entregar bulto']);
    expect(pod.requests, isEmpty);
    expect(find.text('Sin entregas registradas'), findsOneWidget);
  });

  testWidgets('cancelar la confirmación del cliente no registra la entrega', (
    tester,
  ) async {
    final scanner = FakeCodeScanner([validLabelQr(), null]);
    final pod = FakeRecordProofOfDelivery();
    await pumpCarrierScanScreen(
      tester,
      const CarrierDeliverScreen(),
      scanner: scanner,
      proofOfDelivery: pod,
    );

    await _tapDeliver(tester);

    expect(scanner.requestedTitles, [
      'Entregar bulto',
      'Confirmación del cliente',
    ]);
    expect(pod.requests, isEmpty);
    expect(find.text('Sin entregas registradas'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    final button = tester.widget<FilledButton>(
      findButtonWithText<FilledButton>('Registrar entrega'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('bulto con firma inválida: avisa y no pide la confirmación', (
    tester,
  ) async {
    final scanner = FakeCodeScanner([tamperedLabelQr(), 'CONF']);
    final pod = FakeRecordProofOfDelivery();
    await pumpCarrierScanScreen(
      tester,
      const CarrierDeliverScreen(),
      scanner: scanner,
      proofOfDelivery: pod,
    );

    await _tapDeliver(tester);

    expect(scanner.requestedTitles, ['Entregar bulto']);
    expect(pod.requests, isEmpty);
    expect(
      find.text('Firma inválida: etiqueta editada o falsa.'),
      findsOneWidget,
    );
  });

  testWidgets('QR del bulto que no es etiqueta: avisa y no sigue', (
    tester,
  ) async {
    final scanner = FakeCodeScanner(['no-es-json', 'CONF']);
    final pod = FakeRecordProofOfDelivery();
    await pumpCarrierScanScreen(
      tester,
      const CarrierDeliverScreen(),
      scanner: scanner,
      proofOfDelivery: pod,
    );

    await _tapDeliver(tester);

    expect(scanner.requestedTitles, ['Entregar bulto']);
    expect(pod.requests, isEmpty);
    expect(find.text('el contenido del QR no es JSON'), findsOneWidget);
  });

  testWidgets('dos entregas seguidas: el aviso no tapa el botón del pie', (
    tester,
  ) async {
    final pod = FakeRecordProofOfDelivery();
    await pumpCarrierScanScreen(
      tester,
      const CarrierDeliverScreen(),
      scanner: FakeCodeScanner([
        validLabelQr(),
        'CONF-1',
        validLabelQr(),
        'CONF-2',
      ]),
      proofOfDelivery: pod,
    );

    await _tapDeliver(tester);
    final snack = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(
      snack.margin,
      const EdgeInsets.fromLTRB(16, 0, 16, kBottomActionClearance),
    );
    expect(
      tester.getRect(_snackSurface()).bottom,
      lessThanOrEqualTo(
        tester
            .getRect(findButtonWithText<FilledButton>('Registrar entrega'))
            .top,
      ),
    );

    // Segundo toque enseguida, con el aviso todavía visible.
    await _tapDeliver(tester);

    expect(pod.requests.map((r) => r.confirmation), ['CONF-1', 'CONF-2']);
    expect(find.text(vectorSku), findsNWidgets(2));
  });
}
