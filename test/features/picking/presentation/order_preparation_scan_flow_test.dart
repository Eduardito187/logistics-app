import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
import '../picking_test_harness.dart';

// Flujo escaneo -> submit de `_prepareUnit`: escanear el EAN registra la
// PreparationScanRequest, marca la unidad, imprime su ZPL y avisa. El escáner
// de cámara se reemplaza con FakeCodeScanner vía codeScannerProvider.

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
  required FakeCodeScanner scanner,
  required FakeLabelPrinter printer,
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
        codeScannerProvider.overrideWithValue(scanner.call),
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
  Future<SubmitOutcome> Function(PreparationScanRequest scan)? onRecordScan,
}) => FakePickingRepository(
  onGetOrderLabels: (_) async => [
    buildLabel(labelId: 'L1', sku: 'SKU1', zpl: 'ZPL_L1'),
  ],
  onRecordScan: onRecordScan,
);

Future<void> _tapPrepare(WidgetTester tester) async {
  await tester.tap(find.text('Escanear EAN e imprimir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('camino feliz: escanea EAN, registra, marca, imprime y avisa', (
    tester,
  ) async {
    final repo = _repo();
    final scanner = FakeCodeScanner(['7790001112223']);
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

    // Se pidió un escaneo de EAN (no QR).
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
    // Marcada, impresa y con aviso de éxito.
    expect(printer.printed, ['ZPL_L1']);
    expect(find.text('1/1'), findsOneWidget);
    expect(find.text('Reimprimir etiqueta'), findsOneWidget);
    expect(find.text('Unidad preparada e impresa.'), findsOneWidget);
  });

  testWidgets('sin GPS el escaneo no se traba: lat/lng van en cero', (
    tester,
  ) async {
    final repo = _repo();
    await _pump(
      tester,
      repo: repo,
      scanner: FakeCodeScanner(['EAN']),
      printer: FakeLabelPrinter(),
      seedState: _withLane,
    );

    await _tapPrepare(tester);

    expect(repo.recordScanCalls, 1);
    expect(repo.lastScan!.lat, 0);
    expect(repo.lastScan!.lng, 0);
  });

  testWidgets('cancelar el escaneo no registra, no marca ni imprime', (
    tester,
  ) async {
    final repo = _repo();
    final scanner = FakeCodeScanner([null]);
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
      await _pump(
        tester,
        repo: repo,
        scanner: FakeCodeScanner(['EAN']),
        printer: printer,
        seedState: _withLane,
      );

      await _tapPrepare(tester);

      expect(repo.recordScanCalls, 1);
      expect(printer.printed, ['ZPL_L1']);
      expect(find.text('1/1'), findsOneWidget);
      // Offline invisible: encolado se informa igual que enviado.
      expect(find.text('Unidad preparada e impresa.'), findsOneWidget);
    },
  );

  testWidgets('registro fallido (failed): no marca ni imprime y avisa', (
    tester,
  ) async {
    final repo = _repo(onRecordScan: (_) async => SubmitOutcome.failed);
    final printer = FakeLabelPrinter();
    await _pump(
      tester,
      repo: repo,
      scanner: FakeCodeScanner(['EAN']),
      printer: printer,
      seedState: _withLane,
    );

    await _tapPrepare(tester);

    expect(repo.recordScanCalls, 1);
    expect(printer.printed, isEmpty);
    expect(find.text('0/1'), findsOneWidget);
    expect(
      find.text('No se pudo registrar. Intentá de nuevo.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'sin impresora: la unidad queda preparada pero NO se anuncia "impresa"',
    (tester) async {
      final repo = _repo();
      final printer = FakeLabelPrinter(throwOnPrint: true);
      await _pump(
        tester,
        repo: repo,
        scanner: FakeCodeScanner(['EAN']),
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
    final scanner = FakeCodeScanner(['EAN']);
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
    final scanner = FakeCodeScanner(['EAN']);
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
    final scanner = FakeCodeScanner(['EAN']);
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
    final scanner = FakeCodeScanner(['LANE-7', 'EAN']);
    await _pump(
      tester,
      repo: repo,
      scanner: scanner,
      printer: FakeLabelPrinter(),
    );

    await _tapPrepare(tester);
    await tester.tap(find.text('Escanear'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(scanner.requestedTitles, ['Escanear carril', 'Escanear EAN']);
    expect(repo.lastScan!.vehicleId, 'LANE-7');
    expect(find.text('Unidad preparada e impresa.'), findsOneWidget);
  });
}
