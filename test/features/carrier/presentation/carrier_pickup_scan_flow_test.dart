import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/offline/submit_outcome.dart';
import 'package:logistics_app/core/widgets/app_snack.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_pickup_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../support/fake_code_scanner.dart';
import '../carrier_scan_harness.dart';
import '../../../support/button_finders.dart';

// Flujo RECOGER: escanear el QR firmado -> verificar Ed25519 offline
// (scanAndVerifyLabel) -> registrar el escaneo de carga en la cola -> fila con
// su pastilla de estado + aviso. La cámara se reemplaza con FakeCodeScanner.

Future<void> _tapScan(WidgetTester tester) async {
  await tester.tap(findButtonWithText<FilledButton>('Escanear bulto'));
  await tester.pumpAndSettle();
}

/// Superficie visible del aviso (el widget SnackBar incluye su margen).
Finder _snackSurface() => find
    .descendant(of: find.byType(SnackBar), matching: find.byType(Material))
    .first;

void main() {
  testWidgets('QR válido: registra el recojo con GPS y muestra la fila', (
    tester,
  ) async {
    final scanner = FakeCodeScanner([validLabelQr()]);
    final loadScan = FakeRecordLoadScan();
    await pumpCarrierScanScreen(
      tester,
      const CarrierPickupScreen(),
      scanner: scanner,
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

    expect(find.text('Sin bultos recogidos'), findsNothing);
    expect(find.text(vectorSku), findsOneWidget);
    expect(find.textContaining(vectorUnitId), findsOneWidget);
    expect(find.text('Enviado'), findsOneWidget);
    expect(find.text('Registrado.'), findsOneWidget);
  });

  testWidgets('sin GPS el recojo igual se registra con lat/lng en cero', (
    tester,
  ) async {
    final loadScan = FakeRecordLoadScan();
    await pumpCarrierScanScreen(
      tester,
      const CarrierPickupScreen(),
      scanner: FakeCodeScanner([validLabelQr()]),
      loadScan: loadScan,
    );

    await _tapScan(tester);

    expect(loadScan.requests.single.lat, 0);
    expect(loadScan.requests.single.lng, 0);
  });

  testWidgets('encolado offline: se ve igual que enviado (offline invisible)', (
    tester,
  ) async {
    await pumpCarrierScanScreen(
      tester,
      const CarrierPickupScreen(),
      scanner: FakeCodeScanner([validLabelQr()]),
      loadScan: FakeRecordLoadScan(SubmitOutcome.queued),
    );

    await _tapScan(tester);

    expect(find.text('Enviado'), findsOneWidget);
    expect(find.text('Pendiente'), findsNothing);
    expect(find.text('Registrado.'), findsOneWidget);
  });

  testWidgets('dos recojos quedan listados, el último arriba', (tester) async {
    final loadScan = FakeRecordLoadScan();
    await pumpCarrierScanScreen(
      tester,
      const CarrierPickupScreen(),
      scanner: FakeCodeScanner([validLabelQr(), validLabelQr()]),
      loadScan: loadScan,
    );

    await _tapScan(tester);
    // Sin esperar a que se vaya el aviso: flota encima del botón y el segundo
    // toque llega enseguida (antes había que esperar ~4 s).
    expect(find.byType(SnackBar), findsOneWidget);
    await tester.tap(
      findButtonWithText<FilledButton>('Escanear bulto'),
      warnIfMissed: true,
    );
    await tester.pumpAndSettle();

    expect(loadScan.requests, hasLength(2));
    expect(find.text(vectorSku), findsNWidgets(2));
  });

  testWidgets('el aviso flota encima del botón del pie y no lo tapa', (
    tester,
  ) async {
    await pumpCarrierScanScreen(
      tester,
      const CarrierPickupScreen(),
      scanner: FakeCodeScanner([validLabelQr()]),
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

  testWidgets('aviso de firma inválida: corto y encima del botón', (
    tester,
  ) async {
    await pumpCarrierScanScreen(
      tester,
      const CarrierPickupScreen(),
      scanner: FakeCodeScanner([tamperedLabelQr(), validLabelQr()]),
    );

    await _tapScan(tester);

    final snack = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(
      snack.margin,
      const EdgeInsets.fromLTRB(16, 0, 16, kBottomActionClearance),
    );
    expect(snack.duration, kShortSnackDuration);
    expect(
      tester.getRect(_snackSurface()).bottom,
      lessThanOrEqualTo(
        tester.getRect(findButtonWithText<FilledButton>('Escanear bulto')).top,
      ),
    );

    // Reintento inmediato con una etiqueta válida: el aviso no se apila.
    await _tapScan(tester);
    expect(find.text(vectorSku), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Registrado.'), findsOneWidget);
  });

  testWidgets('cancelar el escaneo no registra nada', (tester) async {
    final scanner = FakeCodeScanner([null]);
    final loadScan = FakeRecordLoadScan();
    await pumpCarrierScanScreen(
      tester,
      const CarrierPickupScreen(),
      scanner: scanner,
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

  testWidgets('firma inválida (QR editado): avisa y no registra', (
    tester,
  ) async {
    final loadScan = FakeRecordLoadScan();
    await pumpCarrierScanScreen(
      tester,
      const CarrierPickupScreen(),
      scanner: FakeCodeScanner([tamperedLabelQr()]),
      loadScan: loadScan,
    );

    await _tapScan(tester);

    expect(loadScan.requests, isEmpty);
    expect(
      find.text('Firma inválida: etiqueta editada o falsa.'),
      findsOneWidget,
    );
    expect(find.text('Sin bultos recogidos'), findsOneWidget);
  });

  testWidgets('clave desconocida: avisa que no se puede verificar', (
    tester,
  ) async {
    final loadScan = FakeRecordLoadScan();
    await pumpCarrierScanScreen(
      tester,
      const CarrierPickupScreen(),
      scanner: FakeCodeScanner([validLabelQr()]),
      labelScanner: unknownKeyLabelScanner(),
      loadScan: loadScan,
    );

    await _tapScan(tester);

    expect(loadScan.requests, isEmpty);
    expect(
      find.text('Etiqueta de una clave desconocida: no se puede verificar.'),
      findsOneWidget,
    );
  });

  testWidgets('QR que no es etiqueta: avisa el motivo y no registra', (
    tester,
  ) async {
    final loadScan = FakeRecordLoadScan();
    await pumpCarrierScanScreen(
      tester,
      const CarrierPickupScreen(),
      scanner: FakeCodeScanner(['hola mundo']),
      loadScan: loadScan,
    );

    await _tapScan(tester);

    expect(loadScan.requests, isEmpty);
    expect(find.text('el contenido del QR no es JSON'), findsOneWidget);
  });

  testWidgets('sin claves públicas configuradas: avisa y no registra', (
    tester,
  ) async {
    final loadScan = FakeRecordLoadScan();
    await pumpCarrierScanScreen(
      tester,
      const CarrierPickupScreen(),
      scanner: FakeCodeScanner([validLabelQr()]),
      labelScanner: LabelScanner(null),
      loadScan: loadScan,
    );

    await _tapScan(tester);

    expect(loadScan.requests, isEmpty);
    expect(
      find.text('La app no tiene claves públicas de etiquetas configuradas.'),
      findsOneWidget,
    );
  });
}
