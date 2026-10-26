import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/offline/submit_outcome.dart';
import 'package:logistics_app/core/widgets/app_snack.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_pickup_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../store/fake_continuous_scanner.dart';
import '../carrier_scan_harness.dart';
import '../../../support/button_finders.dart';

// Flujo RECOGER con escaneo CONTINUO: la cámara queda abierta y cada QR firmado
// se verifica (Ed25519 offline), se registra en la cola y suma una fila; el
// aviso de cada bulto va sobre la cámara y al terminar hay un resumen. La
// cámara se reemplaza con FakeContinuousScanner (varios códigos por sesión).

Future<void> _tapScan(WidgetTester tester) async {
  await tester.tap(findButtonWithText<FilledButton>('Escanear bulto'));
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
  late String qrC;

  setUpAll(() async {
    signer = await TestLabelSigner.create();
    qrA = await signer.qr(id: 'U-A', order: 'DM-1', sku: 'SKU-A');
    qrB = await signer.qr(id: 'U-B', order: 'DM-1', sku: 'SKU-B');
    qrC = await signer.qr(id: 'U-C', order: 'DM-2', sku: 'SKU-C');
  });

  testWidgets('QR válido: registra el recojo con GPS y muestra la fila', (
    tester,
  ) async {
    final scanner = FakeContinuousScanner([validLabelQr()]);
    final loadScan = FakeRecordLoadScan();
    await pumpCarrierScanScreen(
      tester,
      const CarrierPickupScreen(),
      continuous: scanner,
      loadScan: loadScan,
      fix: const GpsFix(lat: -16.5, lng: -68.15),
    );

    await _tapScan(tester);

    expect(scanner.requestedTitles, ['Recoger carga']);
    expect(scanner.requestedFormats.single, [BarcodeFormat.qrCode]);
    final request = loadScan.requests.single;
    expect(request.shipmentId, vectorOrder);
    expect(request.unitId, vectorUnitId);
    expect(request.lat, -16.5);
    expect(request.lng, -68.15);
    expect(loadScan.labels.single, 'Recojo · $vectorSku');
    expect(scanner.messages, ['Bulto recogido · $vectorSku']);

    expect(find.text('Sin bultos recogidos'), findsNothing);
    expect(find.text(vectorSku), findsOneWidget);
    expect(find.textContaining(vectorUnitId), findsOneWidget);
    expect(find.text('Enviado'), findsOneWidget);
    expect(find.text('1 bulto recogido.'), findsOneWidget);
  });

  testWidgets('varios bultos en una sola sesión de cámara', (tester) async {
    final scanner = FakeContinuousScanner([qrA, qrB, qrC]);
    final loadScan = FakeRecordLoadScan();
    await pumpCarrierScanScreen(
      tester,
      const CarrierPickupScreen(),
      continuous: scanner,
      labelScanner: signer.scanner(),
      loadScan: loadScan,
    );

    await _tapScan(tester);

    expect(scanner.requestedTitles, hasLength(1));
    expect(loadScan.requests.map((r) => r.unitId), ['U-A', 'U-B', 'U-C']);
    expect(scanner.okCount, 3);
    for (final sku in ['SKU-A', 'SKU-B', 'SKU-C']) {
      expect(find.text(sku), findsOneWidget);
    }
    expect(find.text('3 bultos recogidos.'), findsOneWidget);
  });

  testWidgets('duplicado: el mismo bulto otra vez avisa "Ya recogido"', (
    tester,
  ) async {
    final scanner = FakeContinuousScanner.sessions([
      [qrA, qrA],
      [qrA, qrB],
    ]);
    final loadScan = FakeRecordLoadScan();
    await pumpCarrierScanScreen(
      tester,
      const CarrierPickupScreen(),
      continuous: scanner,
      labelScanner: signer.scanner(),
      loadScan: loadScan,
    );

    await _tapScan(tester);
    await _tapScan(tester);

    expect(loadScan.requests.map((r) => r.unitId), ['U-A', 'U-B']);
    expect(scanner.messages, [
      'Bulto recogido · SKU-A',
      'Ya recogido',
      'Ya recogido',
      'Bulto recogido · SKU-B',
    ]);
    expect(find.text('SKU-A'), findsOneWidget);
  });

  testWidgets('sin GPS el recojo igual se registra con lat/lng en cero', (
    tester,
  ) async {
    final loadScan = FakeRecordLoadScan();
    await pumpCarrierScanScreen(
      tester,
      const CarrierPickupScreen(),
      continuous: FakeContinuousScanner([validLabelQr()]),
      loadScan: loadScan,
    );

    await _tapScan(tester);

    expect(loadScan.requests.single.lat, 0);
    expect(loadScan.requests.single.lng, 0);
  });

  testWidgets('encolado offline: se ve igual que enviado (offline invisible)', (
    tester,
  ) async {
    final scanner = FakeContinuousScanner([validLabelQr()]);
    await pumpCarrierScanScreen(
      tester,
      const CarrierPickupScreen(),
      continuous: scanner,
      loadScan: FakeRecordLoadScan(SubmitOutcome.queued),
    );

    await _tapScan(tester);

    expect(find.text('Enviado'), findsOneWidget);
    expect(find.text('Pendiente'), findsNothing);
    expect(scanner.feedbacks.single.ok, isTrue);
    expect(find.text('1 bulto recogido.'), findsOneWidget);
  });

  testWidgets('rechazo del backend: aviso rojo, fila "Error" y se reintenta', (
    tester,
  ) async {
    final scanner = FakeContinuousScanner.sessions([
      [validLabelQr()],
    ]);
    final loadScan = FakeRecordLoadScan(SubmitOutcome.failed);
    await pumpCarrierScanScreen(
      tester,
      const CarrierPickupScreen(),
      continuous: scanner,
      loadScan: loadScan,
    );

    await _tapScan(tester);

    expect(loadScan.requests, hasLength(1));
    expect(scanner.messages, ['No se pudo registrar. Intentá de nuevo.']);
    expect(find.text('Error'), findsOneWidget);
    // Sin bultos registrados no hay resumen.
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('el resumen flota encima del botón del pie y no lo tapa', (
    tester,
  ) async {
    await pumpCarrierScanScreen(
      tester,
      const CarrierPickupScreen(),
      continuous: FakeContinuousScanner([validLabelQr()]),
    );

    await _tapScan(tester);

    final snack = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(
      snack.margin,
      const EdgeInsets.fromLTRB(16, 0, 16, kBottomActionClearance),
    );
    expect(snack.duration, kShortSnackDuration);
    final snackRect = tester.getRect(_snackSurface());
    final buttonRect = tester.getRect(
      findButtonWithText<FilledButton>('Escanear bulto'),
    );
    expect(snackRect.bottom, lessThanOrEqualTo(buttonRect.top));
  });

  testWidgets('terminar sin leer nada no registra nada', (tester) async {
    final scanner = FakeContinuousScanner(const []);
    final loadScan = FakeRecordLoadScan();
    await pumpCarrierScanScreen(
      tester,
      const CarrierPickupScreen(),
      continuous: scanner,
      loadScan: loadScan,
    );

    await _tapScan(tester);

    expect(scanner.requestedTitles, ['Recoger carga']);
    expect(loadScan.requests, isEmpty);
    expect(find.text('Sin bultos recogidos'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    // El botón vuelve a estar habilitado.
    final button = tester.widget<FilledButton>(
      findButtonWithText<FilledButton>('Escanear bulto'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets(
    'firma inválida (QR editado): aviso rojo y sigue con el próximo',
    (tester) async {
      final scanner = FakeContinuousScanner([
        tamperedLabelQr(),
        validLabelQr(),
      ]);
      final loadScan = FakeRecordLoadScan();
      await pumpCarrierScanScreen(
        tester,
        const CarrierPickupScreen(),
        continuous: scanner,
        loadScan: loadScan,
      );

      await _tapScan(tester);

      expect(scanner.messages, [
        'Etiqueta inválida: editada o falsa',
        'Bulto recogido · $vectorSku',
      ]);
      expect(loadScan.requests.single.unitId, vectorUnitId);
      expect(find.text(vectorSku), findsOneWidget);
    },
  );

  testWidgets('clave desconocida: avisa que no se puede verificar', (
    tester,
  ) async {
    final scanner = FakeContinuousScanner([validLabelQr()]);
    final loadScan = FakeRecordLoadScan();
    await pumpCarrierScanScreen(
      tester,
      const CarrierPickupScreen(),
      continuous: scanner,
      labelScanner: unknownKeyLabelScanner(),
      loadScan: loadScan,
    );

    await _tapScan(tester);

    expect(loadScan.requests, isEmpty);
    expect(scanner.messages, ['Etiqueta inválida: clave desconocida']);
  });

  testWidgets('QR que no es etiqueta: avisa el motivo y no registra', (
    tester,
  ) async {
    final scanner = FakeContinuousScanner(['hola mundo']);
    final loadScan = FakeRecordLoadScan();
    await pumpCarrierScanScreen(
      tester,
      const CarrierPickupScreen(),
      continuous: scanner,
      loadScan: loadScan,
    );

    await _tapScan(tester);

    expect(loadScan.requests, isEmpty);
    expect(scanner.messages, ['el contenido del QR no es JSON']);
  });

  testWidgets('sin claves públicas configuradas: avisa y no registra', (
    tester,
  ) async {
    final scanner = FakeContinuousScanner([validLabelQr()]);
    final loadScan = FakeRecordLoadScan();
    await pumpCarrierScanScreen(
      tester,
      const CarrierPickupScreen(),
      continuous: scanner,
      labelScanner: LabelScanner(null),
      loadScan: loadScan,
    );

    await _tapScan(tester);

    expect(loadScan.requests, isEmpty);
    expect(scanner.messages, [
      'La app no tiene claves públicas de etiquetas configuradas.',
    ]);
  });
}
