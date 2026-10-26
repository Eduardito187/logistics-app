import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/offline/submit_outcome.dart';
import 'package:logistics_app/core/widgets/app_snack.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_deliver_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../support/fake_code_scanner.dart';
import '../../store/fake_continuous_scanner.dart';
import '../carrier_scan_harness.dart';
import '../../../support/button_finders.dart';

// Flujo ENTREGAR: primero el QR de confirmación del cliente (un código, una vez
// por entrega) y después escaneo CONTINUO de sus bultos: cada QR firmado se
// verifica offline y registra su prueba de entrega en la cola. Todos los
// bultos de la tanda deben ser del mismo pedido. Cámaras falsas:
// FakeCodeScanner (confirmación) y FakeContinuousScanner (bultos).

Future<void> _tapDeliver(WidgetTester tester) async {
  await tester.tap(findButtonWithText<FilledButton>('Registrar entrega'));
  await tester.pumpAndSettle();
}

/// Superficie visible del aviso (el widget SnackBar incluye su margen).
Finder _snackSurface() => find
    .descendant(of: find.byType(SnackBar), matching: find.byType(Material))
    .first;

void main() {
  late TestLabelSigner signer;
  late String qrA;
  late String qrB;
  late String qrOther;

  setUpAll(() async {
    signer = await TestLabelSigner.create();
    qrA = await signer.qr(id: 'U-A', order: 'DM-1', sku: 'SKU-A');
    qrB = await signer.qr(id: 'U-B', order: 'DM-1', sku: 'SKU-B');
    qrOther = await signer.qr(id: 'U-X', order: 'DM-9', sku: 'SKU-X');
  });

  testWidgets('confirmación + bulto válido: registra la prueba de entrega', (
    tester,
  ) async {
    final scanner = FakeCodeScanner(['CONF-CLIENTE-1']);
    final units = FakeContinuousScanner([validLabelQr()]);
    final pod = FakeRecordProofOfDelivery();
    await pumpCarrierScanScreen(
      tester,
      const CarrierDeliverScreen(),
      scanner: scanner,
      continuous: units,
      proofOfDelivery: pod,
      fix: const GpsFix(lat: -17.8, lng: -63.2),
    );

    await _tapDeliver(tester);

    expect(scanner.requestedTitles, ['Confirmación del cliente']);
    expect(scanner.requestedFormats, [
      [BarcodeFormat.qrCode],
    ]);
    expect(units.requestedTitles, ['Entregar bultos']);
    expect(units.requestedFormats.single, [BarcodeFormat.qrCode]);
    final request = pod.requests.single;
    expect(request.shipmentId, vectorOrder);
    expect(request.unitId, vectorUnitId);
    expect(request.confirmation, 'CONF-CLIENTE-1');
    expect(request.lat, -17.8);
    expect(request.lng, -63.2);
    expect(pod.labels.single, 'Entrega · $vectorSku');
    expect(units.messages, ['Bulto entregado · $vectorSku']);

    expect(find.text('Sin entregas registradas'), findsNothing);
    expect(find.text(vectorSku), findsOneWidget);
    expect(find.text('Enviado'), findsOneWidget);
    expect(find.text('1 bulto entregado.'), findsOneWidget);
  });

  testWidgets('varios bultos del pedido con una sola confirmación', (
    tester,
  ) async {
    final units = FakeContinuousScanner([qrA, qrB]);
    final pod = FakeRecordProofOfDelivery();
    await pumpCarrierScanScreen(
      tester,
      const CarrierDeliverScreen(),
      scanner: FakeCodeScanner(['CONF-1']),
      continuous: units,
      labelScanner: signer.scanner(),
      proofOfDelivery: pod,
    );

    await _tapDeliver(tester);

    expect(pod.requests.map((r) => r.unitId), ['U-A', 'U-B']);
    expect(pod.requests.map((r) => r.confirmation), ['CONF-1', 'CONF-1']);
    expect(find.text('SKU-A'), findsOneWidget);
    expect(find.text('SKU-B'), findsOneWidget);
    expect(find.text('2 bultos entregados.'), findsOneWidget);
  });

  testWidgets('bulto de otro pedido en la tanda: "No es de este pedido"', (
    tester,
  ) async {
    final units = FakeContinuousScanner([qrA, qrOther, qrB]);
    final pod = FakeRecordProofOfDelivery();
    await pumpCarrierScanScreen(
      tester,
      const CarrierDeliverScreen(),
      scanner: FakeCodeScanner(['CONF-1']),
      continuous: units,
      labelScanner: signer.scanner(),
      proofOfDelivery: pod,
    );

    await _tapDeliver(tester);

    expect(pod.requests.map((r) => r.unitId), ['U-A', 'U-B']);
    expect(units.messages, [
      'Bulto entregado · SKU-A',
      'No es de este pedido',
      'Bulto entregado · SKU-B',
    ]);
    expect(find.text('SKU-X'), findsNothing);
  });

  testWidgets('duplicado: el mismo bulto otra vez avisa "Ya entregado"', (
    tester,
  ) async {
    final units = FakeContinuousScanner([qrA, qrA]);
    final pod = FakeRecordProofOfDelivery();
    await pumpCarrierScanScreen(
      tester,
      const CarrierDeliverScreen(),
      scanner: FakeCodeScanner(['CONF-1']),
      continuous: units,
      labelScanner: signer.scanner(),
      proofOfDelivery: pod,
    );

    await _tapDeliver(tester);

    expect(pod.requests, hasLength(1));
    expect(units.messages, ['Bulto entregado · SKU-A', 'Ya entregado']);
  });

  testWidgets('encolado offline: se ve igual que enviado (offline invisible)', (
    tester,
  ) async {
    await pumpCarrierScanScreen(
      tester,
      const CarrierDeliverScreen(),
      scanner: FakeCodeScanner(['CONF']),
      continuous: FakeContinuousScanner([validLabelQr()]),
      proofOfDelivery: FakeRecordProofOfDelivery(SubmitOutcome.queued),
    );

    await _tapDeliver(tester);

    expect(find.text('Enviado'), findsOneWidget);
    expect(find.text('Pendiente'), findsNothing);
    expect(find.text('1 bulto entregado.'), findsOneWidget);
  });

  testWidgets('envío fallido: fila "Error" y aviso rojo sobre la cámara', (
    tester,
  ) async {
    final units = FakeContinuousScanner([validLabelQr()]);
    await pumpCarrierScanScreen(
      tester,
      const CarrierDeliverScreen(),
      scanner: FakeCodeScanner(['CONF']),
      continuous: units,
      proofOfDelivery: FakeRecordProofOfDelivery(SubmitOutcome.failed),
    );

    await _tapDeliver(tester);

    expect(find.text('Error'), findsOneWidget);
    expect(units.messages, ['No se pudo registrar. Intentá de nuevo.']);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('cancelar la confirmación no abre la cámara de bultos', (
    tester,
  ) async {
    final scanner = FakeCodeScanner([null]);
    final units = FakeContinuousScanner([validLabelQr()]);
    final pod = FakeRecordProofOfDelivery();
    await pumpCarrierScanScreen(
      tester,
      const CarrierDeliverScreen(),
      scanner: scanner,
      continuous: units,
      proofOfDelivery: pod,
    );

    await _tapDeliver(tester);

    expect(scanner.requestedTitles, ['Confirmación del cliente']);
    expect(units.requestedTitles, isEmpty);
    expect(pod.requests, isEmpty);
    expect(find.text('Sin entregas registradas'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    final button = tester.widget<FilledButton>(
      findButtonWithText<FilledButton>('Registrar entrega'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('terminar sin leer bultos no registra la entrega', (
    tester,
  ) async {
    final pod = FakeRecordProofOfDelivery();
    await pumpCarrierScanScreen(
      tester,
      const CarrierDeliverScreen(),
      scanner: FakeCodeScanner(['CONF']),
      continuous: FakeContinuousScanner(const []),
      proofOfDelivery: pod,
    );

    await _tapDeliver(tester);

    expect(pod.requests, isEmpty);
    expect(find.text('Sin entregas registradas'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('bulto con firma inválida: aviso rojo y no entrega', (
    tester,
  ) async {
    final units = FakeContinuousScanner([tamperedLabelQr()]);
    final pod = FakeRecordProofOfDelivery();
    await pumpCarrierScanScreen(
      tester,
      const CarrierDeliverScreen(),
      scanner: FakeCodeScanner(['CONF']),
      continuous: units,
      proofOfDelivery: pod,
    );

    await _tapDeliver(tester);

    expect(pod.requests, isEmpty);
    expect(units.messages, ['Etiqueta inválida: editada o falsa']);
  });

  testWidgets('QR del bulto que no es etiqueta: avisa y no registra', (
    tester,
  ) async {
    final units = FakeContinuousScanner(['no-es-json']);
    final pod = FakeRecordProofOfDelivery();
    await pumpCarrierScanScreen(
      tester,
      const CarrierDeliverScreen(),
      scanner: FakeCodeScanner(['CONF']),
      continuous: units,
      proofOfDelivery: pod,
    );

    await _tapDeliver(tester);

    expect(pod.requests, isEmpty);
    expect(units.messages, ['el contenido del QR no es JSON']);
  });

  testWidgets('dos entregas seguidas: el resumen no tapa el botón del pie', (
    tester,
  ) async {
    final pod = FakeRecordProofOfDelivery();
    await pumpCarrierScanScreen(
      tester,
      const CarrierDeliverScreen(),
      scanner: FakeCodeScanner(['CONF-1', 'CONF-2']),
      continuous: FakeContinuousScanner.sessions([
        [qrA],
        [qrOther],
      ]),
      labelScanner: signer.scanner(),
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

    // Segunda entrega (otro cliente/pedido) enseguida, con el aviso visible.
    await _tapDeliver(tester);

    expect(pod.requests.map((r) => r.confirmation), ['CONF-1', 'CONF-2']);
    expect(find.text('SKU-A'), findsOneWidget);
    expect(find.text('SKU-X'), findsOneWidget);
  });
}
