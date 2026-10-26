import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/core/scanning/continuous_scanner.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';
import 'package:logistics_app/features/driver/presentation/controllers/locally_loaded_units.dart';
import 'package:logistics_app/features/driver/presentation/scan_mode.dart';
import 'package:logistics_app/features/driver/presentation/scan_units_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../support/button_finders.dart';
import '../../../support/screen_sizes.dart';
import '../support/driver_test_support.dart';
import '../support/fake_continuous_scanner.dart';

// Escaneo CONTINUO de bultos (carga/descarga): la cámara se abre una vez por
// tanda (continuousScannerProvider falso con códigos guionizados), cada código
// se verifica offline, se valida contra los bultos del envío, se encola y
// devuelve su aviso corto.

/// Bultos esperados del envío: [units] o, con `null`, sin señal (error).
List<Object> _overrides(
  FakeContinuousScanner scanner,
  FakeOfflineQueue queue, {
  Set<String>? units,
  bool withKeys = true,
  LocationService? location,
}) => [
  continuousScannerProvider.overrideWithValue(scanner.call),
  labelScannerProvider.overrideWithValue(
    vectorLabelScanner(withKeys: withKeys),
  ),
  locationServiceProvider.overrideWithValue(location ?? FakeLocationService()),
  offlineQueueProvider.overrideWithValue(queue),
  driverShipmentUnitsProvider.overrideWith((ref, id) async {
    if (units == null) {
      throw const ApiException(status: 0, title: 'Sin conexión');
    }
    return units;
  }),
];

const _loadScreen = ScanUnitsScreen(
  mode: ScanMode.load,
  shipmentId: 'ship-1',
  title: 'Cargar envío',
);

const _unloadScreen = ScanUnitsScreen(
  mode: ScanMode.unload,
  shipmentId: 'ship-2',
  nodeId: 'node-9',
  title: 'Descargar parada 1',
);

Future<void> _scan(WidgetTester tester, {bool load = true}) async {
  await tester.tap(
    find.text(
      load ? 'Escanear bulto para cargar' : 'Escanear bulto para descargar',
    ),
  );
  await tester.pumpAndSettle();
}

Map<String, Set<String>> _localLoaded(WidgetTester tester) =>
    ProviderScope.containerOf(
      tester.element(find.byType(ScanUnitsScreen)),
    ).read(locallyLoadedUnitsProvider);

void main() {
  testWidgets('modo carga: estado inicial, botón y GPS calentado', (
    tester,
  ) async {
    final location = FakeLocationService();
    await pumpScoped(
      tester,
      child: _loadScreen,
      overrides: _overrides(
        FakeContinuousScanner([]),
        FakeOfflineQueue(SubmitOutcome.sent),
        location: location,
      ),
    );

    expect(find.text('Cargar envío'), findsOneWidget);
    expect(find.text('Sin bultos'), findsOneWidget);
    expect(find.text('Escanea el primer bulto para empezar.'), findsOneWidget);
    expect(find.text('0 bulto(s) registrados'), findsOneWidget);
    expect(find.text('Escanear bulto para cargar'), findsOneWidget);
    // Al entrar se calienta el GPS (sin esperarlo).
    expect(location.prefetchCount, 1);
  });

  testWidgets('modo descarga: etiqueta del botón de descarga', (tester) async {
    await pumpScoped(
      tester,
      child: _unloadScreen,
      overrides: _overrides(
        FakeContinuousScanner([]),
        FakeOfflineQueue(SubmitOutcome.sent),
      ),
    );

    expect(find.text('Descargar parada 1'), findsOneWidget);
    expect(find.text('Escanear bulto para descargar'), findsOneWidget);
  });

  testWidgets('carga: bulto válido → recordLoadScan y "Bulto 1/2 cargado"', (
    tester,
  ) async {
    final scanner = FakeContinuousScanner.single([validLabelQr()]);
    final queue = FakeOfflineQueue(SubmitOutcome.sent);
    await pumpScoped(
      tester,
      child: _loadScreen,
      overrides: _overrides(
        scanner,
        queue,
        units: {vectorUnitId, 'otro-bulto'},
        location: FakeLocationService(
          fix: const GpsFix(lat: -17.8, lng: -63.2),
        ),
      ),
    );

    await _scan(tester);

    expect(scanner.titles, ['Cargar bultos']);
    expect(scanner.formats.single, [BarcodeFormat.qrCode]);
    expect(scanner.messages, ['Bulto 1/2 cargado']);
    expect(scanner.feedbacks.single.ok, isTrue);
    expect(queue.lastKind, 'recordLoadScan');
    final payload = queue.submissions.single;
    expect(payload['shipment_id'], 'ship-1');
    expect(payload['unit_id'], vectorUnitId);
    expect(payload['lat'], -17.8);
    expect(payload['lng'], -63.2);
    expect(payload.containsKey('node_id'), isFalse);

    // Al volver: lista con el bulto, pastilla y contador.
    expect(find.text(vectorUnitId), findsOneWidget);
    expect(find.text('Registrado'), findsOneWidget);
    expect(find.text('1 bulto(s) registrados'), findsOneWidget);
    expect(find.text('Sin bultos'), findsNothing);
    // La pantalla de Carga ya lo cuenta aunque siga en la cola.
    expect(_localLoaded(tester)['ship-1'], {vectorUnitId});
  });

  testWidgets('varios bultos en una sola sesión de cámara', (tester) async {
    final scanner = FakeContinuousScanner.single([
      unsignedLabelQr('U-1'),
      unsignedLabelQr('U-2'),
      unsignedLabelQr('U-3'),
    ]);
    final queue = FakeOfflineQueue(SubmitOutcome.sent);
    await pumpScoped(
      tester,
      child: _loadScreen,
      overrides: _overrides(
        scanner,
        queue,
        units: {'U-1', 'U-2', 'U-3', 'U-4', 'U-5'},
        withKeys: false,
      ),
    );

    await _scan(tester);

    // Una sola apertura de cámara para los tres bultos.
    expect(scanner.titles, hasLength(1));
    expect(scanner.messages, [
      'Bulto 1/5 cargado',
      'Bulto 2/5 cargado',
      'Bulto 3/5 cargado',
    ]);
    expect(queue.submissions.map((p) => p['unit_id']), ['U-1', 'U-2', 'U-3']);
    expect(find.text('3 bulto(s) registrados'), findsOneWidget);
    // El último escaneado arriba.
    expect(
      tester.getTopLeft(find.text('U-3')).dy,
      lessThan(tester.getTopLeft(find.text('U-1')).dy),
    );
    final button = tester.widget<FilledButton>(findButton<FilledButton>());
    expect(button.onPressed, isNotNull);
  });

  testWidgets('duplicado: "Ya registrado" y no se encola dos veces', (
    tester,
  ) async {
    final scanner = FakeContinuousScanner([
      [unsignedLabelQr('U-1'), unsignedLabelQr('U-1')],
      // Segunda tanda: el mismo bulto sigue registrado.
      [unsignedLabelQr('U-1')],
    ]);
    final queue = FakeOfflineQueue(SubmitOutcome.sent);
    await pumpScoped(
      tester,
      child: _loadScreen,
      overrides: _overrides(scanner, queue, units: {'U-1'}, withKeys: false),
    );

    await _scan(tester);
    await _scan(tester);

    expect(scanner.messages, [
      'Bulto 1/1 cargado',
      'Ya registrado',
      'Ya registrado',
    ]);
    expect(scanner.feedbacks[1].ok, isFalse);
    expect(queue.submissions, hasLength(1));
    expect(find.text('1 bulto(s) registrados'), findsOneWidget);
  });

  testWidgets('bulto ajeno en carga: "Ese bulto no es de este camión"', (
    tester,
  ) async {
    final scanner = FakeContinuousScanner.single([
      unsignedLabelQr('AJENO'),
      unsignedLabelQr('U-1'),
    ]);
    final queue = FakeOfflineQueue(SubmitOutcome.sent);
    await pumpScoped(
      tester,
      child: _loadScreen,
      overrides: _overrides(scanner, queue, units: {'U-1'}, withKeys: false),
    );

    await _scan(tester);

    expect(scanner.messages, [
      'Ese bulto no es de este camión',
      'Bulto 1/1 cargado',
    ]);
    expect(scanner.feedbacks.first.ok, isFalse);
    expect(queue.submissions.map((p) => p['unit_id']), ['U-1']);
    expect(find.text('AJENO'), findsNothing);
  });

  testWidgets('bulto ajeno en descarga: "Ese bulto no es de esta parada"', (
    tester,
  ) async {
    final scanner = FakeContinuousScanner.single([unsignedLabelQr('AJENO')]);
    final queue = FakeOfflineQueue(SubmitOutcome.sent);
    await pumpScoped(
      tester,
      child: _unloadScreen,
      overrides: _overrides(scanner, queue, units: {'U-1'}, withKeys: false),
    );

    await _scan(tester, load: false);

    expect(scanner.titles, ['Descargar bultos']);
    expect(scanner.messages, ['Ese bulto no es de esta parada']);
    expect(queue.submissions, isEmpty);
  });

  testWidgets('sin señal: no se valida pertenencia y se encola igual', (
    tester,
  ) async {
    final scanner = FakeContinuousScanner.single([
      unsignedLabelQr('U-1'),
      unsignedLabelQr('U-2'),
    ]);
    final queue = FakeOfflineQueue(SubmitOutcome.queued);
    await pumpScoped(
      tester,
      child: _loadScreen,
      // units: null → la lista de bultos del envío no llegó (sin conexión).
      overrides: _overrides(scanner, queue, withKeys: false),
    );

    await _scan(tester);

    // Sin total conocido: el aviso muestra solo el conteo.
    expect(scanner.messages, ['Bulto 1 cargado', 'Bulto 2 cargado']);
    expect(queue.submissions, hasLength(2));
    // Offline invisible: lo encolado se ve igual que lo enviado.
    expect(find.text('En cola'), findsNothing);
    expect(find.text('Registrado'), findsNWidgets(2));
    expect(_localLoaded(tester)['ship-1'], {'U-1', 'U-2'});
  });

  testWidgets('descarga: recordUnloadScan con el nodo y "descargado"', (
    tester,
  ) async {
    final scanner = FakeContinuousScanner.single([validLabelQr()]);
    final queue = FakeOfflineQueue(SubmitOutcome.queued);
    await pumpScoped(
      tester,
      child: _unloadScreen,
      overrides: _overrides(scanner, queue, units: {vectorUnitId}),
    );

    await _scan(tester, load: false);

    expect(scanner.messages, ['Bulto 1/1 descargado']);
    expect(queue.lastKind, 'recordUnloadScan');
    final payload = queue.submissions.single;
    expect(payload['shipment_id'], 'ship-2');
    expect(payload['unit_id'], vectorUnitId);
    expect(payload['node_id'], 'node-9');
    // Sin fix GPS se registra igual (offline-first) con 0,0.
    expect(payload['lat'], 0);
    expect(payload['lng'], 0);
    // La descarga no toca el conteo local de carga.
    expect(_localLoaded(tester), isEmpty);
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
      overrides: _overrides(
        FakeContinuousScanner.single([validLabelQr()]),
        queue,
      ),
    );

    await _scan(tester, load: false);

    expect(queue.submissions.single['node_id'], 'ship-3');
  });

  testWidgets('etiqueta con firma inválida: "Etiqueta inválida"', (
    tester,
  ) async {
    final scanner = FakeContinuousScanner.single([
      tamperedLabelQr(),
      'no-es-json',
    ]);
    final queue = FakeOfflineQueue(SubmitOutcome.sent);
    await pumpScoped(
      tester,
      child: _loadScreen,
      overrides: _overrides(scanner, queue, units: {vectorUnitId}),
    );

    await _scan(tester);

    expect(scanner.messages, ['Etiqueta inválida', 'Etiqueta inválida']);
    expect(scanner.feedbacks.every((f) => !f.ok), isTrue);
    expect(queue.submissions, isEmpty);
    expect(find.text('0 bulto(s) registrados'), findsOneWidget);
  });

  testWidgets(
    'fallo al registrar: aviso rojo, fila Error y se puede reintentar',
    (tester) async {
      final scanner = FakeContinuousScanner([
        [unsignedLabelQr('U-1')],
        [unsignedLabelQr('U-1')],
      ]);
      final queue = FakeOfflineQueue(SubmitOutcome.failed);
      await pumpScoped(
        tester,
        child: _loadScreen,
        overrides: _overrides(scanner, queue, units: {'U-1'}, withKeys: false),
      );

      await _scan(tester);
      await _scan(tester);

      // Un fallido no cuenta como registrado: el reintento se encola de nuevo.
      expect(scanner.messages, [
        'No se pudo registrar. Reintentá.',
        'No se pudo registrar. Reintentá.',
      ]);
      expect(queue.submissions, hasLength(2));
      // Una sola fila por bulto (el reintento reemplaza la anterior).
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('0 bulto(s) registrados'), findsOneWidget);
      expect(_localLoaded(tester), isEmpty);
    },
  );

  testWidgets('terminar sin leer nada no registra', (tester) async {
    final queue = FakeOfflineQueue(SubmitOutcome.sent);
    await pumpScoped(
      tester,
      child: _loadScreen,
      overrides: _overrides(FakeContinuousScanner([[]]), queue),
    );

    await _scan(tester);

    expect(queue.submissions, isEmpty);
    expect(find.text('Sin bultos'), findsOneWidget);
    expect(find.text('0 bulto(s) registrados'), findsOneWidget);
    final button = tester.widget<FilledButton>(findButton<FilledButton>());
    expect(button.onPressed, isNotNull);
  });

  testOnScreens('lista tras una tanda: botón fijo visible y sin desbordes', (
    tester,
    screen,
  ) async {
    await pumpScoped(
      tester,
      child: withTextScale(_loadScreen),
      overrides: _overrides(
        FakeContinuousScanner.single([
          for (var i = 1; i <= 12; i++) unsignedLabelQr('BULTO-$i'),
        ]),
        FakeOfflineQueue(SubmitOutcome.sent),
        withKeys: false,
      ),
    );

    await _scan(tester);

    expect(find.text('12 bulto(s) registrados'), findsOneWidget);
    final buttonRect = tester.getRect(findButton<FilledButton>());
    expect(buttonRect.bottom, lessThanOrEqualTo(screen.size.height));
    expect(buttonRect.height, greaterThanOrEqualTo(56));
  });
}
