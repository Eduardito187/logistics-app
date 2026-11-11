import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/emitted_label.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/printing/label_printer.dart';
import 'package:logistics_app/core/printing/printer_config.dart';
import 'package:logistics_app/core/widgets/empty_state.dart';
import 'package:logistics_app/features/picking/data/repositories/picking_repository_impl.dart';
import 'package:logistics_app/features/picking/domain/entities/preparation_state.dart';
import 'package:logistics_app/features/picking/presentation/controllers/preparation_controller.dart';
import 'package:logistics_app/features/picking/presentation/order_preparation_screen.dart';
import 'package:logistics_app/features/picking/presentation/widgets/label_batch_sheet.dart';
import 'package:logistics_app/features/picking/presentation/widgets/progress_card.dart';
import 'package:logistics_app/features/picking/presentation/widgets/unit_tile.dart';

import '../picking_test_harness.dart';
import '../../../support/button_finders.dart';

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
          preparationControllerProvider(
            orderNumber,
          ).overrideWith(() => _SeededPrep(seedState)),
      ],
      child: MaterialApp(
        home: OrderPreparationScreen(orderNumber: orderNumber),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fakePrinter;
}

Finder _sheetFields() => find.descendant(
  of: find.byType(LabelBatchSheet),
  matching: find.byType(TextField),
);

void main() {
  testWidgets('sin etiquetas: muestra la LISTA de productos del pedido', (
    tester,
  ) async {
    await _pump(
      tester,
      repo: FakePickingRepository(
        onGetOrderLabels: (_) async => [],
        onGetOrderDispatchLines: (_) async => buildDispatchLines(
          lines: [
            buildDispatchLine(productName: 'Lavadora 9 kg', sku: 'SKU-A'),
          ],
        ),
      ),
    );

    expect(find.text('Pedido EXT-1'), findsOneWidget); // AppBar
    // Producto del pedido (nombre + SKU), ya resuelto desde dispatch-lines.
    expect(find.text('Lavadora 9 kg'), findsOneWidget);
    expect(find.textContaining('SKU-A'), findsOneWidget);
    expect(
      findButtonWithText<FilledButton>('Emitir etiquetas del pedido'),
      findsOneWidget,
    );
  });

  testWidgets('con etiquetas muestra progreso y una fila por unidad', (
    tester,
  ) async {
    // El ListView es perezoso: en 800x600 la segunda fila no se construye.
    tester.view.physicalSize = const Size(1200, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
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
    expect(find.text('Productos (2)'), findsOneWidget);
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

    expect(find.text('Productos (1)'), findsOneWidget);
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

  testWidgets('emitir POR ORDEN: sin formulario, emite directo', (
    tester,
  ) async {
    final repo = FakePickingRepository(
      onGetOrderLabels: (_) async => [],
      onGetOrderDispatchLines: (_) async => buildDispatchLines(),
      onEmitOrderLabels: (_) async => [buildLabel(), buildLabel(labelId: 'L2')],
    );
    await _pump(tester, repo: repo);

    await tester.tap(
      findButtonWithText<FilledButton>('Emitir etiquetas del pedido'),
    );
    await tester.pumpAndSettle();

    // No se abre ningún formulario de origen/destino/SKU.
    expect(find.byType(LabelBatchSheet), findsNothing);
    expect(repo.emitOrderCalls, 1);
    expect(repo.lastEmitOrderNumber, 'EXT-1');
    expect(repo.emitCalls, 0); // nunca el emit explícito (legado)
    expect(find.text('Etiquetas emitidas: 2.'), findsOneWidget);
  });

  testWidgets('emitir por orden con 409 avisa que ya hay etiquetas', (
    tester,
  ) async {
    final repo = FakePickingRepository(
      onGetOrderLabels: (_) async => [],
      onGetOrderDispatchLines: (_) async => buildDispatchLines(),
      onEmitOrderLabels: (_) async =>
          throw const ApiException(status: 409, title: 'Conflicto'),
    );
    await _pump(tester, repo: repo);

    await tester.tap(
      findButtonWithText<FilledButton>('Emitir etiquetas del pedido'),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('El pedido ya tiene todas sus etiquetas.'),
      findsOneWidget,
    );
  });

  testWidgets('emitir por orden con error genérico muestra el snack de error', (
    tester,
  ) async {
    final repo = FakePickingRepository(
      onGetOrderLabels: (_) async => [],
      onGetOrderDispatchLines: (_) async => buildDispatchLines(),
      onEmitOrderLabels: (_) async =>
          throw const ApiException(status: 500, title: 'Boom'),
    );
    await _pump(tester, repo: repo);

    await tester.tap(
      findButtonWithText<FilledButton>('Emitir etiquetas del pedido'),
    );
    await tester.pumpAndSettle();

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

    await tester.tap(find.text('Anular y emitir de nuevo'));
    await tester.pumpAndSettle();

    // Líneas pre-cargadas por SKU (SKU1 x2); sólo faltan origen/destino/motivo.
    await tester.enterText(_sheetFields().at(0), 'LPZ'); // origen
    await tester.enterText(_sheetFields().at(1), 'SCZ'); // destino
    await tester.enterText(_sheetFields().at(2), 'dañada'); // motivo
    final reprintSubmit = find.descendant(
      of: find.byType(LabelBatchSheet),
      matching: findButtonWithText<FilledButton>('Reimprimir'),
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

    // La unidad preparada muestra "Imprimir de nuevo".
    expect(find.text('0/1'), findsNothing);
    expect(find.text('1/1'), findsOneWidget);

    final btn = find.text('Imprimir de nuevo');
    await tester.ensureVisible(btn);
    // ensureVisible solo mueve el scroll: hace falta un frame para que el
    // botón quede en su nueva posición antes de tocarlo.
    await tester.pump();
    await tester.tap(btn);
    await tester.pumpAndSettle();

    expect(printer.printed, ['ZPL_L1']);
    expect(find.text('Etiqueta enviada a la impresora.'), findsOneWidget);
  });

  testWidgets('impresión sin confirmación (9100): mensaje veraz', (
    tester,
  ) async {
    final labels = <EmittedLabel>[buildLabel(labelId: 'L1', zpl: 'ZPL_L1')];
    final printer = FakeLabelPrinter()
      ..outcome = const PrintOutcome.sentUnconfirmed();
    await _pump(
      tester,
      printer: printer,
      repo: FakePickingRepository(onGetOrderLabels: (_) async => labels),
      seedState: const PreparationState(
        preparedUnitIds: {'L1'},
        vehicleId: 'V1',
        lane: 'A1',
      ),
    );

    final btn = find.text('Imprimir de nuevo');
    await tester.ensureVisible(btn);
    await tester.pump();
    await tester.tap(btn);
    await tester.pumpAndSettle();

    expect(printer.printed, ['ZPL_L1']);
    // Viaja el dibujo de la etiqueta por si la impresora es de oficina.
    expect(printer.renders.single, isNotNull);
    expect(
      find.text(
        'Enviado. Esta impresora no confirma la impresión; revisá que haya '
        'salido.',
      ),
      findsOneWidget,
    );
    expect(find.text('Etiqueta enviada a la impresora.'), findsNothing);
  });

  testWidgets('la impresora rechaza: se muestra el motivo, no "Ajustes"', (
    tester,
  ) async {
    final labels = <EmittedLabel>[buildLabel(labelId: 'L1', zpl: 'ZPL_L1')];
    final printer = _RejectingPrinter();
    await _pump(
      tester,
      printer: printer,
      repo: FakePickingRepository(onGetOrderLabels: (_) async => labels),
      seedState: const PreparationState(
        preparedUnitIds: {'L1'},
        vehicleId: 'V1',
        lane: 'A1',
      ),
    );

    final btn = find.text('Imprimir de nuevo');
    await tester.ensureVisible(btn);
    await tester.pump();
    await tester.tap(btn);
    await tester.pumpAndSettle();

    expect(find.text('La impresora está ocupada.'), findsOneWidget);
    expect(find.text('Seleccioná una impresora en Ajustes.'), findsNothing);
  });

  group('código que no es un número de pedido', () {
    // Bug: el QR de una etiqueta llegaba como número y el header mostraba
    // `Pedido {"v":1,…}` con "El pedido no tiene productos".
    Future<List<String>> pumpInvalid(
      WidgetTester tester,
      String orderNumber,
    ) async {
      final calls = <String>[];
      await _pump(
        tester,
        orderNumber: orderNumber,
        repo: FakePickingRepository(
          onGetOrderLabels: (o) async {
            calls.add('labels:$o');
            return const [];
          },
          onGetOrderDispatchLines: (o) async {
            calls.add('lines:$o');
            return buildDispatchLines(orderReference: o);
          },
        ),
      );
      return calls;
    }

    testWidgets('JSON de etiqueta: título "Pedido" y aviso, sin repositorio', (
      tester,
    ) async {
      final calls = await pumpInvalid(tester, '{"v":1}');

      expect(find.text('Pedido'), findsOneWidget);
      expect(find.textContaining('{"v"'), findsNothing);
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Ese código no es un número de pedido'), findsOneWidget);
      expect(
        find.text(
          'Volvé atrás y escaneá la etiqueta de un producto del pedido.',
        ),
        findsOneWidget,
      );
      expect(find.text('El pedido no tiene productos'), findsNothing);
      expect(calls, isEmpty);
    });

    testWidgets('texto con espacios: mismo aviso, sin repositorio', (
      tester,
    ) async {
      final calls = await pumpInvalid(tester, 'hola mundo');

      expect(find.text('Pedido'), findsOneWidget);
      expect(find.text('Ese código no es un número de pedido'), findsOneWidget);
      expect(calls, isEmpty);
    });

    testWidgets('un número válido SÍ consulta el pedido', (tester) async {
      final calls = await pumpInvalid(tester, 'DIS-123456');

      expect(find.text('Pedido DIS-123456'), findsOneWidget);
      expect(find.text('Ese código no es un número de pedido'), findsNothing);
      expect(calls, contains('labels:DIS-123456'));
    });
  });
}

/// Impresora que rechaza el trabajo con un motivo propio.
class _RejectingPrinter extends FakeLabelPrinter {
  @override
  Future<PrintOutcome> printLabel({
    required String zpl,
    LabelRenderer? render,
    String? jobName,
    PrinterConfig? to,
  }) async {
    printed.add(zpl);
    throw const PrinterException('La impresora está ocupada.');
  }
}
