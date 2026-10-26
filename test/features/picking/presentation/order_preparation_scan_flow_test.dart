import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/emitted_label.dart';
import 'package:logistics_app/core/api/models/preparation_scan_request.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/offline/submit_outcome.dart';
import 'package:logistics_app/core/printing/label_printer.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:logistics_app/features/picking/data/repositories/picking_repository_impl.dart';
import 'package:logistics_app/features/picking/domain/entities/preparation_state.dart';
import 'package:logistics_app/features/picking/presentation/controllers/preparation_controller.dart';
import 'package:logistics_app/features/picking/presentation/order_preparation_screen.dart';
import 'package:logistics_app/features/picking/presentation/widgets/assign_lane_dialog.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../support/fake_code_scanner.dart';
import '../../store/fake_continuous_scanner.dart';
import '../picking_test_harness.dart';

// Flujo escaneo -> submit del preparador con escaneo CONTINUO: cada EAN leído
// registra la PreparationScanRequest de una unidad, la marca y ENCOLA su
// etiqueta en la impresora (no frena la cámara); al terminar se avisa una vez.
// La cámara continua se reemplaza con FakeContinuousScanner y la del carril
// (diálogo, un solo código) con FakeCodeScanner.

/// Semilla del progreso (p. ej. con carril ya asignado).
class _SeededPrep extends PreparationController {
  _SeededPrep(this.seed);
  final PreparationState seed;
  @override
  PreparationState build() => seed;
}

const _withLane = PreparationState(vehicleId: 'V1', lane: 'V1');

Future<void> _pump(
  WidgetTester tester, {
  required FakePickingRepository repo,
  required FakeContinuousScanner scanner,
  required FakeLabelPrinter printer,
  FakeCodeScanner? laneScanner,
  PreparationState? seedState,
  GpsFix? fix,
}) async {
  // Superficie alta: el ListView es perezoso y la fila de la unidad queda abajo.
  tester.view.physicalSize = const Size(1200, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pickingRepositoryProvider.overrideWithValue(repo),
        labelPrinterProvider.overrideWithValue(printer),
        locationServiceProvider.overrideWithValue(
          FakeLocationService(fix: fix),
        ),
        continuousScannerProvider.overrideWithValue(scanner.call),
        codeScannerProvider.overrideWithValue(
          (laneScanner ?? FakeCodeScanner(const [])).call,
        ),
        if (seedState != null)
          preparationControllerProvider(
            'EXT-1',
          ).overrideWith(() => _SeededPrep(seedState)),
      ],
      child: const MaterialApp(
        home: OrderPreparationScreen(orderNumber: 'EXT-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

FakePickingRepository _repo({
  List<EmittedLabel>? labels,
  Future<SubmitOutcome> Function(PreparationScanRequest scan)? onRecordScan,
  List<PreparationScanRequest>? scans,
}) => FakePickingRepository(
  onGetOrderLabels: (_) async =>
      labels ?? [buildLabel(labelId: 'L1', sku: 'SKU1', zpl: 'ZPL_L1')],
  onRecordScan: (scan) async {
    scans?.add(scan);
    return onRecordScan == null ? SubmitOutcome.sent : onRecordScan(scan);
  },
);

/// Tres unidades: dos del SKU1 y una del SKU2.
List<EmittedLabel> _threeUnits() => [
  buildLabel(labelId: 'L1', sku: 'SKU1', zpl: 'ZPL_L1'),
  buildLabel(labelId: 'L2', sku: 'SKU1', zpl: 'ZPL_L2', lineNumber: 1),
  buildLabel(labelId: 'L3', sku: 'SKU2', zpl: 'ZPL_L3', lineNumber: 2),
];

Future<void> _tapPrepare(WidgetTester tester) async {
  await tester.tap(find.text('Escanear EAN e imprimir').first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('camino feliz: escanea EAN, registra, marca, imprime y avisa', (
    tester,
  ) async {
    final repo = _repo();
    final scanner = FakeContinuousScanner(['7790001112223']);
    final printer = FakeLabelPrinter();
    await _pump(
      tester,
      repo: repo,
      scanner: scanner,
      printer: printer,
      seedState: _withLane,
      fix: const GpsFix(lat: -17.78, lng: -63.18),
    );
    expect(find.text('0/1'), findsOneWidget);

    await _tapPrepare(tester);

    // Se abrió la cámara continua de EAN (no QR).
    expect(scanner.requestedTitles, ['Escanear EAN']);
    expect(scanner.requestedFormats.single, [
      BarcodeFormat.ean13,
      BarcodeFormat.code128,
    ]);
    // Se registró la preparación con el pedido, la unidad, el carril y el GPS.
    expect(repo.recordScanCalls, 1);
    final scan = repo.lastScan!;
    expect(scan.shipmentId, 'EXT-1');
    expect(scan.unitId, 'L1');
    expect(scan.vehicleId, 'V1');
    expect(scan.lat, -17.78);
    expect(scan.lng, -63.18);
    expect(scanner.messages, ['Unidad 1/1 preparada · SKU SKU1']);
    // Marcada, impresa y con aviso de éxito.
    expect(printer.printed, ['ZPL_L1']);
    expect(find.text('1/1'), findsOneWidget);
    expect(find.text('Reimprimir etiqueta'), findsOneWidget);
    expect(find.text('Unidad preparada e impresa.'), findsOneWidget);
  });

  testWidgets('varias unidades en una sesión: SKU coincidente o la siguiente', (
    tester,
  ) async {
    final scans = <PreparationScanRequest>[];
    final repo = _repo(labels: _threeUnits(), scans: scans);
    final scanner = FakeContinuousScanner(['EAN-A', 'SKU2', 'EAN-B']);
    final printer = FakeLabelPrinter();
    await _pump(
      tester,
      repo: repo,
      scanner: scanner,
      printer: printer,
      seedState: _withLane,
    );

    await _tapPrepare(tester);

    // Una sola apertura de cámara para las tres unidades.
    expect(scanner.requestedTitles, hasLength(1));
    // 1º la tocada (L1); "SKU2" coincide con L3; el resto va a L2.
    expect(scans.map((s) => s.unitId), ['L1', 'L3', 'L2']);
    expect(scanner.messages, [
      'Unidad 1/3 preparada · SKU SKU1',
      'Unidad 2/3 preparada · SKU SKU2',
      'Unidad 3/3 preparada · SKU SKU1',
    ]);
    // La impresión sale en cola, en el orden del escaneo.
    expect(printer.printed, ['ZPL_L1', 'ZPL_L3', 'ZPL_L2']);
    expect(find.text('3/3'), findsOneWidget);
    expect(find.text('3 unidades preparadas e impresas.'), findsOneWidget);
  });

  testWidgets('pedido completo: un EAN de más avisa y no registra', (
    tester,
  ) async {
    final repo = _repo();
    final scanner = FakeContinuousScanner(['EAN', 'EAN-OTRO']);
    await _pump(
      tester,
      repo: repo,
      scanner: scanner,
      printer: FakeLabelPrinter(),
      seedState: _withLane,
    );

    await _tapPrepare(tester);

    expect(repo.recordScanCalls, 1);
    expect(scanner.messages, [
      'Unidad 1/1 preparada · SKU SKU1',
      'Pedido completo: no quedan unidades',
    ]);
    expect(scanner.feedbacks.map((f) => f.ok), [true, false]);
  });

  testWidgets('sin GPS el escaneo no se traba: lat/lng van en cero', (
    tester,
  ) async {
    final repo = _repo();
    await _pump(
      tester,
      repo: repo,
      scanner: FakeContinuousScanner(['EAN']),
      printer: FakeLabelPrinter(),
      seedState: _withLane,
    );

    await _tapPrepare(tester);

    expect(repo.recordScanCalls, 1);
    expect(repo.lastScan!.lat, 0);
    expect(repo.lastScan!.lng, 0);
  });

  testWidgets('terminar sin leer nada no registra, no marca ni imprime', (
    tester,
  ) async {
    final repo = _repo();
    final scanner = FakeContinuousScanner(const []);
    final printer = FakeLabelPrinter();
    await _pump(
      tester,
      repo: repo,
      scanner: scanner,
      printer: printer,
      seedState: _withLane,
    );

    await _tapPrepare(tester);

    expect(scanner.requestedTitles, ['Escanear EAN']);
    expect(repo.recordScanCalls, 0);
    expect(printer.printed, isEmpty);
    expect(find.text('0/1'), findsOneWidget);
    expect(find.text('Escanear EAN e imprimir'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
    'encolado offline (queued): marca, imprime y avisa como enviado',
    (tester) async {
      final repo = _repo(onRecordScan: (_) async => SubmitOutcome.queued);
      final printer = FakeLabelPrinter();
      final scanner = FakeContinuousScanner(['EAN']);
      await _pump(
        tester,
        repo: repo,
        scanner: scanner,
        printer: printer,
        seedState: _withLane,
      );

      await _tapPrepare(tester);

      expect(repo.recordScanCalls, 1);
      expect(printer.printed, ['ZPL_L1']);
      expect(find.text('1/1'), findsOneWidget);
      // Offline invisible: encolado se informa igual que enviado.
      expect(scanner.feedbacks.single.ok, isTrue);
      expect(find.text('Unidad preparada e impresa.'), findsOneWidget);
    },
  );

  testWidgets('registro fallido (failed): no marca ni imprime y avisa', (
    tester,
  ) async {
    final repo = _repo(onRecordScan: (_) async => SubmitOutcome.failed);
    final printer = FakeLabelPrinter();
    final scanner = FakeContinuousScanner(['EAN']);
    await _pump(
      tester,
      repo: repo,
      scanner: scanner,
      printer: printer,
      seedState: _withLane,
    );

    await _tapPrepare(tester);

    expect(repo.recordScanCalls, 1);
    expect(printer.printed, isEmpty);
    expect(find.text('0/1'), findsOneWidget);
    expect(scanner.messages, ['No se pudo registrar. Intentá de nuevo.']);
    expect(scanner.okCount, 0);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('un rechazo en la ráfaga: el mismo EAN reintenta esa unidad', (
    tester,
  ) async {
    final scans = <PreparationScanRequest>[];
    var tries = 0;
    final repo = _repo(
      onRecordScan: (_) async =>
          tries++ == 0 ? SubmitOutcome.failed : SubmitOutcome.sent,
      scans: scans,
    );
    final scanner = FakeContinuousScanner(['EAN', 'EAN']);
    await _pump(
      tester,
      repo: repo,
      scanner: scanner,
      printer: FakeLabelPrinter(),
      seedState: _withLane,
    );

    await _tapPrepare(tester);

    expect(scans.map((s) => s.unitId), ['L1', 'L1']);
    expect(scanner.messages, [
      'No se pudo registrar. Intentá de nuevo.',
      'Unidad 1/1 preparada · SKU SKU1',
    ]);
    expect(find.text('1/1'), findsOneWidget);
  });

  testWidgets(
    'sin impresora: la unidad queda preparada pero NO se anuncia "impresa"',
    (tester) async {
      final repo = _repo();
      final printer = FakeLabelPrinter(throwOnPrint: true);
      await _pump(
        tester,
        repo: repo,
        scanner: FakeContinuousScanner(['EAN']),
        printer: printer,
        seedState: _withLane,
      );

      await _tapPrepare(tester);

      expect(repo.recordScanCalls, 1);
      expect(printer.printed, ['ZPL_L1']); // se intentó imprimir
      expect(find.text('1/1'), findsOneWidget);
      // Debe quedar visible el aviso de la impresora, no un éxito falso.
      expect(find.text('Seleccioná una impresora en Ajustes.'), findsOneWidget);
      expect(find.text('Unidad preparada e impresa.'), findsNothing);
    },
  );

  testWidgets('sin carril: pide asignarlo y, si se cancela, no escanea', (
    tester,
  ) async {
    final repo = _repo();
    final scanner = FakeContinuousScanner(['EAN']);
    await _pump(
      tester,
      repo: repo,
      scanner: scanner,
      printer: FakeLabelPrinter(),
    );

    await _tapPrepare(tester);
    expect(find.byType(AssignLaneDialog), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.byType(AssignLaneDialog), findsNothing);
    expect(
      find.text('Asigná un carril o vehículo para empezar.'),
      findsOneWidget,
    );
    expect(scanner.requestedTitles, isEmpty); // ni siquiera abrió el escáner
    expect(repo.recordScanCalls, 0);
  });

  testWidgets('sin carril: guardar uno vacío tampoco deja escanear', (
    tester,
  ) async {
    final repo = _repo();
    final scanner = FakeContinuousScanner(['EAN']);
    await _pump(
      tester,
      repo: repo,
      scanner: scanner,
      printer: FakeLabelPrinter(),
    );

    await _tapPrepare(tester);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Asigná un carril o vehículo para empezar.'),
      findsOneWidget,
    );
    expect(scanner.requestedTitles, isEmpty);
    expect(repo.recordScanCalls, 0);
  });

  testWidgets('sin carril: tras asignarlo a mano sigue al escaneo de EAN', (
    tester,
  ) async {
    final repo = _repo();
    final scanner = FakeContinuousScanner(['EAN']);
    final printer = FakeLabelPrinter();
    await _pump(tester, repo: repo, scanner: scanner, printer: printer);

    await _tapPrepare(tester);
    await tester.enterText(find.byType(TextField), 'Carril 3');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(scanner.requestedTitles, ['Escanear EAN']);
    expect(repo.recordScanCalls, 1);
    expect(repo.lastScan!.vehicleId, 'Carril 3');
    expect(printer.printed, ['ZPL_L1']);
    expect(find.text('1/1'), findsOneWidget);
  });

  testWidgets('sin carril: escanear el carril en el diálogo y luego el EAN', (
    tester,
  ) async {
    final repo = _repo();
    final laneScanner = FakeCodeScanner(['LANE-7']);
    final scanner = FakeContinuousScanner(['EAN']);
    await _pump(
      tester,
      repo: repo,
      scanner: scanner,
      laneScanner: laneScanner,
      printer: FakeLabelPrinter(),
    );

    await _tapPrepare(tester);
    await tester.tap(find.text('Escanear'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(laneScanner.requestedTitles, ['Escanear carril']);
    expect(scanner.requestedTitles, ['Escanear EAN']);
    expect(repo.lastScan!.vehicleId, 'LANE-7');
    expect(find.text('Unidad preparada e impresa.'), findsOneWidget);
  });
}
