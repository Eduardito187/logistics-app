import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:logistics_app/core/widgets/app_snack.dart';
import 'package:logistics_app/features/driver/presentation/scan_mode.dart';
import 'package:logistics_app/features/driver/presentation/scan_units_screen.dart';

import '../../../support/fake_code_scanner.dart';
import '../support/driver_test_support.dart';
import '../../../support/button_finders.dart';
import '../../../support/screen_sizes.dart';

// Escaneo repetido de bultos (carga/descarga). El escaneo se inyecta con
// codeScannerProvider y la etiqueta se verifica offline con el vector Ed25519
// compartido; cada bulto válido se registra en la cola offline (fake).

List<Object> _overrides(
  FakeCodeScanner fake,
  FakeOfflineQueue queue, {
  GpsFix? fix,
}) => [
  codeScannerProvider.overrideWithValue(fake.call),
  labelScannerProvider.overrideWithValue(vectorLabelScanner()),
  locationServiceProvider.overrideWithValue(FakeLocationService(fix: fix)),
  offlineQueueProvider.overrideWithValue(queue),
];

const _loadScreen = ScanUnitsScreen(
  mode: ScanMode.load,
  shipmentId: 'ship-1',
  title: 'Cargar envío',
);

void main() {
  testWidgets('modo carga: estado inicial y etiqueta del botón', (
    tester,
  ) async {
    await pumpScoped(tester, child: _loadScreen);

    expect(find.text('Cargar envío'), findsOneWidget);
    expect(find.text('Sin bultos'), findsOneWidget);
    expect(find.text('Escanea el primer bulto para empezar.'), findsOneWidget);
    expect(find.text('0 bulto(s) registrados'), findsOneWidget);
    expect(find.text('Escanear bulto para cargar'), findsOneWidget);
  });

  testWidgets('modo descarga: etiqueta del botón de descarga', (tester) async {
    await pumpScoped(
      tester,
      child: const ScanUnitsScreen(
        mode: ScanMode.unload,
        shipmentId: 'ship-1',
        nodeId: 'node-1',
        title: 'Descargar parada 1',
      ),
    );

    expect(find.text('Descargar parada 1'), findsOneWidget);
    expect(find.text('Escanear bulto para descargar'), findsOneWidget);
  });

  testWidgets('carga: un bulto válido se registra como recordLoadScan', (
    tester,
  ) async {
    final fake = FakeCodeScanner([validLabelQr()]);
    final queue = FakeOfflineQueue(SubmitOutcome.sent);
    await pumpScoped(
      tester,
      child: _loadScreen,
      overrides: _overrides(
        fake,
        queue,
        fix: const GpsFix(lat: -17.8, lng: -63.2),
      ),
    );

    await tester.tap(find.text('Escanear bulto para cargar'));
    await tester.pumpAndSettle();

    expect(fake.requestedTitles, ['Escanear bulto']);
    expect(find.byType(ScannerScreen), findsNothing);
    expect(queue.lastKind, 'recordLoadScan');
    final payload = queue.submissions.single;
    expect(payload['shipment_id'], 'ship-1');
    expect(payload['unit_id'], vectorUnitId);
    expect(payload['lat'], -17.8);
    expect(payload['lng'], -63.2);
    expect(payload.containsKey('node_id'), isFalse);

    // La lista muestra el bulto con su pastilla y el contador sube.
    expect(find.text(vectorUnitId), findsOneWidget);
    // Offline invisible: la pastilla dice "Registrado" (sin estado de envío).
    expect(find.text('Registrado'), findsOneWidget);
    expect(find.text('1 bulto(s) registrados'), findsOneWidget);
    expect(find.text('Sin bultos'), findsNothing);
    expect(find.text('Registrado.'), findsOneWidget);
  });

  testWidgets('descarga: se registra recordUnloadScan con el nodo', (
    tester,
  ) async {
    final queue = FakeOfflineQueue(SubmitOutcome.queued);
    await pumpScoped(
      tester,
      child: const ScanUnitsScreen(
        mode: ScanMode.unload,
        shipmentId: 'ship-2',
        nodeId: 'node-9',
        title: 'Descargar parada 1',
      ),
      overrides: _overrides(FakeCodeScanner([validLabelQr()]), queue),
    );

    await tester.tap(find.text('Escanear bulto para descargar'));
    await tester.pumpAndSettle();

    expect(queue.lastKind, 'recordUnloadScan');
    final payload = queue.submissions.single;
    expect(payload['shipment_id'], 'ship-2');
    expect(payload['unit_id'], vectorUnitId);
    expect(payload['node_id'], 'node-9');
    // Sin fix GPS se registra igual (offline-first) con 0,0.
    expect(payload['lat'], 0);
    expect(payload['lng'], 0);

    // Offline invisible: lo encolado se ve igual que lo enviado.
    expect(find.text('En cola'), findsNothing);
    expect(find.text('Registrado'), findsOneWidget);
    expect(find.text('Registrado.'), findsOneWidget);
  });

  testWidgets('descarga sin nodo usa el shipmentId como node_id', (
    tester,
  ) async {
    final queue = FakeOfflineQueue(SubmitOutcome.sent);
    await pumpScoped(
      tester,
      child: const ScanUnitsScreen(
        mode: ScanMode.unload,
        shipmentId: 'ship-3',
        title: 'Descargar',
      ),
      overrides: _overrides(FakeCodeScanner([validLabelQr()]), queue),
    );

    await tester.tap(find.text('Escanear bulto para descargar'));
    await tester.pumpAndSettle();

    expect(queue.submissions.single['node_id'], 'ship-3');
  });

  testWidgets('escaneos repetidos se acumulan; un fallo queda como Error', (
    tester,
  ) async {
    final queue = FakeOfflineQueue(SubmitOutcome.failed);
    await pumpScoped(
      tester,
      child: _loadScreen,
      overrides: _overrides(
        FakeCodeScanner([validLabelQr(), validLabelQr()]),
        queue,
      ),
    );

    await tester.tap(find.text('Escanear bulto para cargar'));
    await tester.pumpAndSettle();
    // El aviso flota encima del botón del pie (bottomClearance): se puede
    // escanear de nuevo sin esperar a que se cierre.
    expect(find.byType(SnackBar), findsOneWidget);
    await tester.tap(find.text('Escanear bulto para cargar'));
    await tester.pumpAndSettle();

    expect(queue.submissions, hasLength(2));
    expect(find.text('2 bulto(s) registrados'), findsOneWidget);
    expect(find.text('Error'), findsNWidgets(2));
    expect(
      find.text('No se pudo registrar. Intentá de nuevo.'),
      findsOneWidget,
    );
    // El botón vuelve a habilitarse tras cada escaneo.
    final button = tester.widget<FilledButton>(findButton<FilledButton>());
    expect(button.onPressed, isNotNull);
  });

  testWidgets('cancelar el escaneo no registra nada', (tester) async {
    final queue = FakeOfflineQueue(SubmitOutcome.sent);
    await pumpScoped(
      tester,
      child: _loadScreen,
      overrides: _overrides(FakeCodeScanner([null]), queue),
    );

    await tester.tap(find.text('Escanear bulto para cargar'));
    await tester.pumpAndSettle();

    expect(queue.submissions, isEmpty);
    expect(find.text('Sin bultos'), findsOneWidget);
    expect(find.text('0 bulto(s) registrados'), findsOneWidget);
    expect(find.text('Etiqueta no válida'), findsNothing);
    final button = tester.widget<FilledButton>(findButton<FilledButton>());
    expect(button.onPressed, isNotNull);
  });

  testWidgets('etiqueta con firma inválida: avisa y no registra', (
    tester,
  ) async {
    final queue = FakeOfflineQueue(SubmitOutcome.sent);
    await pumpScoped(
      tester,
      child: _loadScreen,
      overrides: _overrides(FakeCodeScanner([tamperedLabelQr()]), queue),
    );

    await tester.tap(find.text('Escanear bulto para cargar'));
    await tester.pumpAndSettle();

    expect(queue.submissions, isEmpty);
    expect(find.text('Etiqueta no válida'), findsOneWidget);
    expect(find.text('0 bulto(s) registrados'), findsOneWidget);
  });

  group('avisos sobre el botón fijo del pie', () {
    const clearance = EdgeInsets.fromLTRB(16, 0, 16, kBottomActionClearance);

    testOnScreens('el aviso del registro flota encima del botón', (
      tester,
      screen,
    ) async {
      await pumpScoped(
        tester,
        child: _loadScreen,
        overrides: _overrides(
          FakeCodeScanner([validLabelQr()]),
          FakeOfflineQueue(SubmitOutcome.sent),
        ),
      );

      await tester.tap(find.text('Escanear bulto para cargar'));
      await tester.pumpAndSettle();

      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snack.margin, clearance);
      // Geometría: el aviso termina por encima del botón (no lo tapa).
      // (El rect del SnackBar incluye su margen; se mide la tarjeta visible.)
      final snackRect = tester.getRect(
        find
            .descendant(
              of: find.byType(SnackBar),
              matching: find.byType(Material),
            )
            .first,
      );
      final buttonRect = tester.getRect(findButton<FilledButton>());
      expect(snackRect.bottom, lessThanOrEqualTo(buttonRect.top));
    });

    testWidgets('el aviso de etiqueta no válida también lleva el margen', (
      tester,
    ) async {
      await pumpScoped(
        tester,
        child: _loadScreen,
        overrides: _overrides(
          FakeCodeScanner([tamperedLabelQr()]),
          FakeOfflineQueue(SubmitOutcome.sent),
        ),
      );

      await tester.tap(find.text('Escanear bulto para cargar'));
      await tester.pumpAndSettle();

      expect(find.text('Etiqueta no válida'), findsOneWidget);
      expect(tester.widget<SnackBar>(find.byType(SnackBar)).margin, clearance);
    });
  });
}
