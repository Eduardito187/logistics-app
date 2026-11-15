import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/layout/breakpoints.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/printing/label_printer.dart';
import 'package:logistics_app/core/theme/app_theme.dart';
import 'package:logistics_app/features/picking/data/repositories/picking_repository_impl.dart';
import 'package:logistics_app/features/picking/domain/entities/preparation_state.dart';
import 'package:logistics_app/features/picking/presentation/controllers/preparation_controller.dart';
import 'package:logistics_app/features/picking/presentation/order_preparation_screen.dart';
import 'package:logistics_app/features/picking/presentation/orders_worklist_screen.dart';
import 'package:logistics_app/features/picking/presentation/prepare_order_screen.dart';
import 'package:logistics_app/features/picking/presentation/widgets/order_card.dart';
import 'package:logistics_app/features/picking/presentation/widgets/progress_card.dart';
import 'package:logistics_app/features/picking/presentation/widgets/unit_tile.dart';

import '../../../support/button_finders.dart';
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
          // La pantalla usa `ordersWorklistProvider`, armado desde el caso de
          // uso: se siembra el repositorio.
          pickingRepositoryProvider.overrideWithValue(
            FakePickingRepository(onListShipments: () async => orders),
          ),
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
    // Acción principal: escanear la etiqueta de un producto.
    final scan = findButtonWithText<FilledButton>('Escanear producto');
    expect(scan, findsOneWidget);
    final scanRect = tester.getRect(scan);
    expect(scanRect.width, lessThanOrEqualTo(AppBreakpoints.maxFormWidth));
    expect(scanRect.right, lessThanOrEqualTo(screen.size.width));
    // Alternativa: escribir el número y "Abrir pedido" (alcanzable scrolleando
    // en el teléfono chico con letra grande).
    final open = findButtonWithText<OutlinedButton>('Abrir pedido');
    await tester.ensureVisible(open);
    await tester.pumpAndSettle();
    expect(open, findsOneWidget);
    expect(tester.getRect(open).right, lessThanOrEqualTo(screen.size.width));
    expect(find.text('Escanear pedido'), findsNothing);
    expect(find.text('Ver etiquetas'), findsNothing);
  });

  testOnScreens('preparar por código: aviso de número inválido sin desbordes', (
    tester,
    screen,
  ) async {
    await tester.pumpWidget(_app(const PrepareOrderScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '{"v":1,"t":"PKG"}');
    final open = findButtonWithText<OutlinedButton>('Abrir pedido');
    await tester.ensureVisible(open);
    await tester.tap(open);
    await tester.pumpAndSettle();

    expect(
      find.text('Ese no es un número de pedido válido (ej. DIS-123456).'),
      findsOneWidget,
    );
  });

  testOnScreens('pedido con código que no es un número: aviso sin desbordes', (
    tester,
    screen,
  ) async {
    var repoCalls = 0;
    await tester.pumpWidget(
      _app(
        const OrderPreparationScreen(orderNumber: '{"v":1,"t":"PKG"}'),
        overrides: [
          pickingRepositoryProvider.overrideWithValue(
            FakePickingRepository(
              onGetOrderLabels: (_) async {
                repoCalls++;
                return const [];
              },
              onGetOrderDispatchLines: (_) async {
                repoCalls++;
                return buildDispatchLines();
              },
            ),
          ),
          labelPrinterProvider.overrideWithValue(FakeLabelPrinter()),
          locationServiceProvider.overrideWithValue(FakeLocationService()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pedido'), findsOneWidget);
    expect(find.text('Ese código no es un número de pedido'), findsOneWidget);
    expect(repoCalls, 0);
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
      find.text('Productos (30)'),
      200,
      scrollable: unitsScroll,
    );
    // Robusto: scrollear al SKU del primer producto (evita `.first` sobre un
    // match vacío a mitad del drag).
    await tester.scrollUntilVisible(
      find.text(skus.first),
      200,
      scrollable: unitsScroll,
    );
    // La lista de unidades es perezosa: no se construyen las 30 filas.
    expect(
      tester.widgetList(find.byType(UnitTile)).length,
      lessThan(labels.length),
    );

    if (wide) {
      // Tablet grande: dos paneles (el de progreso no scrollea con las
      // unidades), así que ambos están visibles a la vez: progreso a la
      // izquierda, unidades a la derecha.
      final progress = tester.getRect(find.byType(ProgressCard));
      final firstUnit = tester.getRect(find.byType(UnitTile).first);
      expect(firstUnit.left, greaterThan(progress.right));
    } else {
      // Columna única (apilado): progreso arriba y unidades abajo en el MISMO
      // scroll — se reveló la primera unidad scrolleando hacia abajo. En
      // teléfono chico el progreso + la primera unidad no entran juntos en
      // pantalla, así que no se miden a la vez.
      expect(find.byType(UnitTile), findsWidgets);
    }

    // Se puede llegar a la última unidad scrolleando (sin desbordes).
    final last = find.text(skus.last);
    await tester.scrollUntilVisible(
      last,
      600,
      scrollable: unitsScroll,
      maxScrolls: 200,
    );
    expect(last, findsOneWidget);
  });

  testOnScreens('pedido sin etiquetas: lista de productos y botón Emitir', (
    tester,
    screen,
  ) async {
    await tester.pumpWidget(
      _app(
        const OrderPreparationScreen(orderNumber: 'EXT-1'),
        overrides: [
          pickingRepositoryProvider.overrideWithValue(
            FakePickingRepository(
              onGetOrderDispatchLines: (_) async => buildDispatchLines(
                lines: [buildDispatchLine(productName: 'Televisor 55"')],
              ),
            ),
          ),
          labelPrinterProvider.overrideWithValue(FakeLabelPrinter()),
          locationServiceProvider.overrideWithValue(FakeLocationService()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Televisor 55"'), findsOneWidget); // producto del pedido
    final button = tester.getRect(find.text('Emitir etiquetas del pedido'));
    expect(button.right, lessThanOrEqualTo(screen.size.width));
  });
}
