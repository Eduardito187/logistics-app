import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/emitted_label.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/printing/label_printer.dart';
import 'package:logistics_app/features/picking/data/repositories/picking_repository_impl.dart';
import 'package:logistics_app/features/picking/domain/entities/preparation_state.dart';
import 'package:logistics_app/features/picking/presentation/controllers/preparation_controller.dart';
import 'package:logistics_app/features/picking/presentation/order_preparation_screen.dart';
import 'package:logistics_app/features/picking/presentation/widgets/label_batch_sheet.dart';
import 'package:logistics_app/features/picking/presentation/widgets/progress_card.dart';
import 'package:logistics_app/features/picking/presentation/widgets/unit_tile.dart';

import '../picking_test_harness.dart';

// Pantalla de armado de un pedido. Se override el repositorio (lecturas y
// escrituras), la impresora y la ubicación con dobles sin HW. El escaneo de EAN
// (scanCode) abre la cámara real y NO es testeable acá: ver FALENCIAS.

/// Semilla del progreso para probar el estado "unidad preparada".
class _SeededPrep extends PreparationController {
  _SeededPrep(this.seed);
  final PreparationState seed;
  @override
  PreparationState build() => seed;
}

Future<FakeLabelPrinter> _pump(
  WidgetTester tester, {
  required FakePickingRepository repo,
  FakeLabelPrinter? printer,
  PreparationState? seedState,
  String orderNumber = 'EXT-1',
}) async {
  final fakePrinter = printer ?? FakeLabelPrinter();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pickingRepositoryProvider.overrideWithValue(repo),
        labelPrinterProvider.overrideWithValue(fakePrinter),
        locationServiceProvider.overrideWithValue(FakeLocationService()),
        if (seedState != null)
          preparationControllerProvider(orderNumber)
              .overrideWith(() => _SeededPrep(seedState)),
      ],
      child: MaterialApp(
        home: OrderPreparationScreen(orderNumber: orderNumber),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fakePrinter;
}

Future<void> _submitSheet(WidgetTester tester) async {
  // El título del sheet y el botón comparten el texto "Emitir etiquetas": se
  // acota al FilledButton de envío dentro del sheet.
  final submit = find.descendant(
    of: find.byType(LabelBatchSheet),
    matching: find.widgetWithText(FilledButton, 'Emitir etiquetas'),
  );
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  await tester.pumpAndSettle();
}

Finder _sheetFields() => find.descendant(
  of: find.byType(LabelBatchSheet),
  matching: find.byType(TextField),
);

void main() {
  testWidgets('sin etiquetas vigentes muestra el estado vacío y "Emitir"', (
    tester,
  ) async {
    await _pump(
      tester,
      repo: FakePickingRepository(onGetOrderLabels: (_) async => []),
    );

    expect(find.text('Pedido EXT-1'), findsOneWidget); // AppBar
    expect(find.text('Sin etiquetas vigentes'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Emitir etiquetas'),
      findsOneWidget,
    );
  });

  testWidgets('con etiquetas muestra progreso y una fila por unidad', (
    tester,
  ) async {
    await _pump(
      tester,
      repo: FakePickingRepository(
        onGetOrderLabels: (_) async => [
          buildLabel(labelId: 'L1', sku: 'SKU1', lineNumber: 1),
          buildLabel(labelId: 'L2', sku: 'SKU2', lineNumber: 2),
        ],
      ),
    );

    expect(find.byType(ProgressCard), findsOneWidget);
    expect(find.text('Unidades (2)'), findsOneWidget);
    expect(find.byType(UnitTile), findsNWidgets(2));
    expect(find.text('0/2'), findsOneWidget); // ninguna preparada aún
  });

  testWidgets('las etiquetas revocadas no cuentan como unidades vigentes', (
    tester,
  ) async {
    await _pump(
      tester,
      repo: FakePickingRepository(
        onGetOrderLabels: (_) async => [
          buildLabel(labelId: 'L1', revoked: false),
          buildLabel(labelId: 'L2', revoked: true),
        ],
      ),
    );

    expect(find.text('Unidades (1)'), findsOneWidget);
    expect(find.byType(UnitTile), findsOneWidget);
  });

  testWidgets('error de red al cargar muestra "No se pudo cargar"', (
    tester,
  ) async {
    await _pump(
      tester,
      repo: FakePickingRepository(
        onGetOrderLabels: (_) async =>
            throw const ApiException(status: 500, title: 'Boom'),
      ),
    );

    expect(find.text('No se pudo cargar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('emitir etiquetas: completa el formulario y confirma', (
    tester,
  ) async {
    final repo = FakePickingRepository(
      onGetOrderLabels: (_) async => [],
      onEmitLabels: (_, _) async => [buildLabel()],
    );
    await _pump(tester, repo: repo);

    await tester.tap(find.widgetWithText(FilledButton, 'Emitir etiquetas'));
    await tester.pumpAndSettle();

    await tester.enterText(_sheetFields().at(0), 'LPZ'); // origen
    await tester.enterText(_sheetFields().at(1), 'SCZ'); // destino
    await tester.enterText(_sheetFields().at(2), 'SKU-9'); // sku (cantidad=1)
    await _submitSheet(tester);

    expect(repo.emitCalls, 1);
    expect(repo.lastEmitOrder, 'EXT-1');
    expect(repo.lastEmitBody?.origin, 'LPZ');
    expect(repo.lastEmitBody?.destination, 'SCZ');
    expect(repo.lastEmitBody?.lines.single.sku, 'SKU-9');
    expect(find.text('Etiquetas emitidas.'), findsOneWidget); // snack éxito
  });

  testWidgets('emitir con 409 avisa que ya hay etiquetas', (tester) async {
    final repo = FakePickingRepository(
      onGetOrderLabels: (_) async => [],
      onEmitLabels: (_, _) async =>
          throw const ApiException(status: 409, title: 'Conflicto'),
    );
    await _pump(tester, repo: repo);

    await tester.tap(find.widgetWithText(FilledButton, 'Emitir etiquetas'));
    await tester.pumpAndSettle();
    await tester.enterText(_sheetFields().at(0), 'LPZ');
    await tester.enterText(_sheetFields().at(1), 'SCZ');
    await tester.enterText(_sheetFields().at(2), 'SKU-9');
    await _submitSheet(tester);

    expect(find.text('El pedido ya tiene etiquetas emitidas.'), findsOneWidget);
  });

  testWidgets('emitir con error genérico muestra el snack de error', (
    tester,
  ) async {
    final repo = FakePickingRepository(
      onGetOrderLabels: (_) async => [],
      onEmitLabels: (_, _) async =>
          throw const ApiException(status: 500, title: 'Boom'),
    );
    await _pump(tester, repo: repo);

    await tester.tap(find.widgetWithText(FilledButton, 'Emitir etiquetas'));
    await tester.pumpAndSettle();
    await tester.enterText(_sheetFields().at(0), 'LPZ');
    await tester.enterText(_sheetFields().at(1), 'SCZ');
    await tester.enterText(_sheetFields().at(2), 'SKU-9');
    await _submitSheet(tester);

    expect(
      find.text('Error del servidor. Probá de nuevo en un momento.'),
      findsOneWidget,
    );
  });

  testWidgets('imprimir todas usa el ZPL firmado del backend', (tester) async {
    final repo = FakePickingRepository(
      onGetOrderLabels: (_) async => [buildLabel(labelId: 'L1')],
      onGetSignedZpl: (_) async => 'ZPL_FIRMADO',
    );
    final printer = await _pump(tester, repo: repo);

    await tester.tap(find.text('Imprimir todas las etiquetas'));
    await tester.pumpAndSettle();

    expect(printer.printed, ['ZPL_FIRMADO']);
    expect(find.text('Enviadas 1 etiquetas a la impresora.'), findsOneWidget);
  });

  testWidgets('imprimir todas cae al ZPL local si falla el backend', (
    tester,
  ) async {
    final repo = FakePickingRepository(
      onGetOrderLabels: (_) async => [
        buildLabel(labelId: 'L1', zpl: 'Z1'),
        buildLabel(labelId: 'L2', zpl: 'Z2'),
      ],
      onGetSignedZpl: (_) async =>
          throw const ApiException(status: 0, title: 'Sin conexión'),
    );
    final printer = await _pump(tester, repo: repo);

    await tester.tap(find.text('Imprimir todas las etiquetas'));
    await tester.pumpAndSettle();

    // Respaldo offline: ZPL local de cada etiqueta concatenado.
    expect(printer.printed, ['Z1\nZ2']);
    expect(find.text('Enviadas 2 etiquetas a la impresora.'), findsOneWidget);
  });

  testWidgets('imprimir todas sin impresora avisa ir a Ajustes', (
    tester,
  ) async {
    final repo = FakePickingRepository(
      onGetOrderLabels: (_) async => [buildLabel(labelId: 'L1')],
      onGetSignedZpl: (_) async => 'ZPL',
    );
    final printer = await _pump(
      tester,
      repo: repo,
      printer: FakeLabelPrinter(throwOnPrint: true),
    );

    await tester.tap(find.text('Imprimir todas las etiquetas'));
    await tester.pumpAndSettle();

    expect(printer.printed, ['ZPL']); // se intentó imprimir
    expect(find.text('Seleccioná una impresora en Ajustes.'), findsOneWidget);
  });

  testWidgets('reimprimir lote: pide motivo y confirma', (tester) async {
    final repo = FakePickingRepository(
      onGetOrderLabels: (_) async => [
        buildLabel(labelId: 'L1', sku: 'SKU1'),
        buildLabel(labelId: 'L2', sku: 'SKU1'),
      ],
      onReprintLabels: (_, _) async => [buildLabel(labelId: 'NEW')],
    );
    await _pump(tester, repo: repo);

    await tester.tap(find.text('Reimprimir lote'));
    await tester.pumpAndSettle();

    // Líneas pre-cargadas por SKU (SKU1 x2); sólo faltan origen/destino/motivo.
    await tester.enterText(_sheetFields().at(0), 'LPZ'); // origen
    await tester.enterText(_sheetFields().at(1), 'SCZ'); // destino
    await tester.enterText(_sheetFields().at(2), 'dañada'); // motivo
    final reprintSubmit = find.descendant(
      of: find.byType(LabelBatchSheet),
      matching: find.widgetWithText(FilledButton, 'Reimprimir'),
    );
    await tester.ensureVisible(reprintSubmit);
    await tester.tap(reprintSubmit);
    await tester.pumpAndSettle();

    expect(repo.reprintCalls, 1);
    expect(repo.lastReprintBody?.reason, 'dañada');
    expect(repo.lastReprintBody?.lines.single.sku, 'SKU1');
    expect(repo.lastReprintBody?.lines.single.quantity, 2);
    expect(
      find.text('Lote reimpreso: se emitieron etiquetas nuevas.'),
      findsOneWidget,
    );
  });

  testWidgets('reimprimir una unidad ya preparada imprime su ZPL', (
    tester,
  ) async {
    final labels = <EmittedLabel>[buildLabel(labelId: 'L1', zpl: 'ZPL_L1')];
    final printer = await _pump(
      tester,
      repo: FakePickingRepository(onGetOrderLabels: (_) async => labels),
      seedState: const PreparationState(
        preparedUnitIds: {'L1'},
        vehicleId: 'V1',
        lane: 'A1',
      ),
    );

    // La unidad preparada muestra "Reimprimir etiqueta".
    expect(find.text('0/1'), findsNothing);
    expect(find.text('1/1'), findsOneWidget);

    final btn = find.text('Reimprimir etiqueta');
    await tester.ensureVisible(btn);
    await tester.tap(btn);
    await tester.pumpAndSettle();

    expect(printer.printed, ['ZPL_L1']);
  });
}
