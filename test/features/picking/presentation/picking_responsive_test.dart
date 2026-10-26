import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/emit_label_line.dart';
import 'package:logistics_app/core/layout/breakpoints.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/printing/label_printer.dart';
import 'package:logistics_app/core/theme/app_theme.dart';
import 'package:logistics_app/features/picking/data/repositories/picking_repository_impl.dart';
import 'package:logistics_app/features/picking/domain/entities/preparation_state.dart';
import 'package:logistics_app/features/picking/presentation/controllers/orders_worklist_controller.dart';
import 'package:logistics_app/features/picking/presentation/controllers/preparation_controller.dart';
import 'package:logistics_app/features/picking/presentation/order_preparation_screen.dart';
import 'package:logistics_app/features/picking/presentation/orders_worklist_screen.dart';
import 'package:logistics_app/features/picking/presentation/prepare_order_screen.dart';
import 'package:logistics_app/features/picking/presentation/widgets/label_batch_sheet.dart';
import 'package:logistics_app/features/picking/presentation/widgets/order_card.dart';
import 'package:logistics_app/features/picking/presentation/widgets/progress_card.dart';
import 'package:logistics_app/features/picking/presentation/widgets/unit_tile.dart';

import '../../../support/screen_sizes.dart';
import '../picking_test_harness.dart';

// Layout de las pantallas del preparador en los 4 tamaños de referencia
// (teléfono chico 320x568 → tablet horizontal 1280x800) con letra a 1.3x y el
// tema real de la app (botones de 56 dp a lo ancho). Un desborde hace fallar
// el test solo.

class _SeededPrep extends PreparationController {
  _SeededPrep(this.seed);
  final PreparationState seed;
  @override
  PreparationState build() => seed;
}

Widget _app(Widget home, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: [...syncBadgeOverrides(), ...overrides],
    child: MaterialApp(theme: AppTheme.light(), home: withTextScale(home)),
  );
}

List<String> _skus(int n) => List.generate(n, (i) => '7790${1000 + i}');

void main() {
  testOnScreens('worklist de pedidos sin desbordes y en columnas en tablet', (
    tester,
    screen,
  ) async {
    final orders = [
      for (var i = 0; i < 12; i++)
        buildShipment(
          externalId: 'DIS-1234567$i',
          customerName: 'Cliente con un nombre bastante largo número $i',
          lineCount: 3,
          quantityPerLine: 2,
        ),
    ];
    await tester.pumpWidget(
      _app(
        const OrdersWorklistScreen(),
        overrides: [
          ordersToPrepareProvider.overrideWith((ref) async => orders),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final cards = find.byType(OrderCard);
    expect(cards, findsWidgets);
    // Perezosa: nunca construye las 12 tarjetas de una en un teléfono.
    if (screen == TestScreen.smallPhone) {
      expect(tester.widgetList(cards).length, lessThan(orders.length));
    }
    final first = tester.getRect(cards.at(0));
    final second = tester.getRect(cards.at(1));
    final columns = AppBreakpoints.columnsFor(screen.size.width - 32);
    if (columns > 1) {
      // En tablet la segunda tarjeta va al lado de la primera.
      expect(second.top, first.top);
      expect(second.left, greaterThan(first.right));
    } else {
      expect(second.top, greaterThan(first.top));
    }
  });

  testOnScreens('preparar por código: formulario acotado en tablet', (
    tester,
    screen,
  ) async {
    await tester.pumpWidget(_app(const PrepareOrderScreen()));
    await tester.pumpAndSettle();

    final field = tester.getRect(find.byType(TextField));
    expect(field.width, lessThanOrEqualTo(AppBreakpoints.maxFormWidth));
    expect(find.text('Escanear pedido'), findsOneWidget);
  });

  testOnScreens('preparación del pedido con muchas unidades', (
    tester,
    screen,
  ) async {
    final skus = _skus(30);
    final labels = [
      for (var i = 0; i < skus.length; i++)
        buildLabel(labelId: 'LBL-0000000$i', sku: skus[i], lineNumber: i + 1),
    ];
    await tester.pumpWidget(
      _app(
        const OrderPreparationScreen(orderNumber: 'EXT-1'),
        overrides: [
          pickingRepositoryProvider.overrideWithValue(
            FakePickingRepository(onGetOrderLabels: (_) async => labels),
          ),
          labelPrinterProvider.overrideWithValue(FakeLabelPrinter()),
          locationServiceProvider.overrideWithValue(FakeLocationService()),
          preparationControllerProvider('EXT-1').overrideWith(
            () => _SeededPrep(
              const PreparationState(
                preparedUnitIds: {'LBL-00000000'},
                vehicleId: 'CAMION-1234',
                lane: 'CARRIL NORTE 12',
              ),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProgressCard), findsOneWidget);
    // En tablet grande hay dos paneles con scroll propio: unidades a la derecha.
    final wide = screen == TestScreen.tabletLandscape;
    final unitsScroll = wide
        ? find.byType(Scrollable).last
        : find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Unidades (30)'),
      200,
      scrollable: unitsScroll,
    );
    await tester.scrollUntilVisible(
      find.byType(UnitTile).first,
      200,
      scrollable: unitsScroll,
    );
    // La lista de unidades es perezosa: no se construyen las 30 filas.
    expect(
      tester.widgetList(find.byType(UnitTile)).length,
      lessThan(labels.length),
    );

    final progress = tester.getRect(find.byType(ProgressCard));
    final firstUnit = tester.getRect(find.byType(UnitTile).first);
    if (wide) {
      // Tablet grande: progreso a la izquierda, unidades a la derecha.
      expect(firstUnit.left, greaterThan(progress.right));
    } else {
      expect(firstUnit.top, greaterThan(progress.bottom));
    }

    // Se puede llegar a la última unidad scrolleando (sin desbordes).
    final last = find.text('SKU ${skus.last}');
    await tester.scrollUntilVisible(
      last,
      600,
      scrollable: unitsScroll,
      maxScrolls: 200,
    );
    expect(last, findsOneWidget);
  });

  testOnScreens('pedido sin etiquetas: estado vacío y botón Emitir', (
    tester,
    screen,
  ) async {
    await tester.pumpWidget(
      _app(
        const OrderPreparationScreen(orderNumber: 'EXT-1'),
        overrides: [
          pickingRepositoryProvider.overrideWithValue(FakePickingRepository()),
          labelPrinterProvider.overrideWithValue(FakeLabelPrinter()),
          locationServiceProvider.overrideWithValue(FakeLocationService()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sin etiquetas vigentes'), findsOneWidget);
    final button = tester.getRect(find.text('Emitir etiquetas'));
    expect(button.right, lessThanOrEqualTo(screen.size.width));
  });

  testOnScreens('hoja de etiquetas (reimpresión) sin desbordes', (
    tester,
    screen,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: withTextScale(
          Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showLabelBatchSheet(
                    context,
                    title: 'Reimprimir etiquetas',
                    submitLabel: 'Reimprimir',
                    requireReason: true,
                    initialLines: const [
                      EmitLabelLine(
                        sku: 'SKU-1',
                        name: 'Heladera',
                        quantity: 2,
                      ),
                      EmitLabelLine(sku: 'SKU-2', name: 'Cocina', quantity: 1),
                      EmitLabelLine(
                        sku: 'SKU-3',
                        name: 'Lavadora',
                        quantity: 3,
                      ),
                    ],
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.byType(LabelBatchSheet), findsOneWidget);
    expect(find.text('Líneas (3)'), findsOneWidget);
    final submit = find.text('Reimprimir');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    expect(submit, findsOneWidget);
  });
}
