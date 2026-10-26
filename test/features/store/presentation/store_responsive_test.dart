import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/node_reception_view_status.dart';
import 'package:logistics_app/core/layout/breakpoints.dart';
import 'package:logistics_app/core/theme/app_theme.dart';
import 'package:logistics_app/features/store/data/repositories/store_repository_impl.dart';
import 'package:logistics_app/features/store/presentation/controllers/selected_store_node_notifier.dart';
import 'package:logistics_app/features/store/presentation/controllers/shelf_locations_notifier.dart';
import 'package:logistics_app/features/store/presentation/controllers/store_controllers.dart';
import 'package:logistics_app/features/store/presentation/counter_pickup_screen.dart';
import 'package:logistics_app/features/store/presentation/node_reception_screen.dart';
import 'package:logistics_app/features/store/presentation/pickup_pod_screen.dart';
import 'package:logistics_app/features/store/presentation/reception_detail_screen.dart';
import 'package:logistics_app/features/store/presentation/widgets/pickup_card.dart';
import 'package:logistics_app/features/store/presentation/widgets/shipment_card.dart';

import '../../../support/button_finders.dart';
import '../../../support/screen_sizes.dart';
import '../store_fixtures.dart';
import '../store_test_harness.dart';

// Layout de las pantallas de Tienda en teléfono chico (320x568), teléfono,
// tablet vertical y horizontal, con la letra del sistema al máximo que permite
// la app (1.3x). Un desborde hace fallar el test solo.

const _longName = 'María Fernanda de los Ángeles Gutiérrez Villarroel';

final _node = storeNode(name: 'Tienda Centro Comercial Las Brisas Norte');
final _shipment = shipment(
  customerName: _longName,
  externalId: 'DM-2600123456789',
  customerPhone: '+591 70000000',
);
final _key = (shipmentId: _shipment.id, nodeId: _node.id);

final _shipments = [
  for (var i = 0; i < 12; i++)
    shipment(id: 'ship-$i', customerName: '$_longName $i', lines: 3),
];

Future<void> _pump(
  WidgetTester tester,
  Widget screen,
  List<Override> overrides,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...syncBadgeOverrides(), ...overrides],
      child: MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => withTextScale(child!),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Ancho que ocupa el contenido: en tablets se limita, en teléfonos no.
void _expectContentWidth(WidgetTester tester, TestScreen screen, Finder list) {
  final width = tester.getSize(list.first).width;
  expect(
    width,
    screen.size.width > AppBreakpoints.maxContentWidth
        ? AppBreakpoints.maxContentWidth
        : screen.size.width,
  );
}

/// El botón está dentro de la pantalla (fijo al pie, sin scrollear).
void _expectOnScreen(WidgetTester tester, TestScreen screen, Finder finder) {
  final rect = tester.getRect(finder);
  expect(rect.bottom, lessThanOrEqualTo(screen.size.height));
  expect(rect.top, greaterThanOrEqualTo(0));
}

void main() {
  testOnScreens('recepción: tienda fija y envíos en lista o grilla', (
    tester,
    screen,
  ) async {
    await _pump(tester, const NodeReceptionScreen(), [
      storeShipmentsProvider.overrideWith((ref) async => _shipments),
      selectedStoreNodeProvider.overrideWithValue(_node),
    ]);

    expect(find.text('Tu tienda'), findsOneWidget);
    _expectContentWidth(tester, screen, find.byType(CustomScrollView));
    // Lista perezosa: no se construyen las 12 tarjetas de una.
    expect(
      find.byType(ShipmentCard).evaluate().length,
      lessThan(_shipments.length),
    );
    final cards = find.byType(ShipmentCard);
    final columns = AppBreakpoints.columnsFor(
      tester.getSize(find.byType(CustomScrollView)).width - 32,
    );
    if (columns > 1) {
      // Grilla en tablets: las dos primeras tarjetas comparten fila.
      expect(
        tester.getTopLeft(cards.at(0)).dy,
        tester.getTopLeft(cards.at(1)).dy,
      );
    } else {
      // Teléfono: una columna a todo el ancho (menos el margen).
      expect(
        tester.getSize(cards.first).width,
        tester.getSize(find.byType(CustomScrollView)).width - 32,
      );
    }
  });

  testOnScreens('recojo en tienda: lista de pedidos sin desbordes', (
    tester,
    screen,
  ) async {
    await _pump(tester, const CounterPickupScreen(), [
      storeShipmentsProvider.overrideWith((ref) async => _shipments),
    ]);

    expect(find.byType(PickupCard), findsWidgets);
    _expectContentWidth(tester, screen, find.byType(CustomScrollView));
    // Se puede llegar al último pedido scrolleando.
    await tester.scrollUntilVisible(
      find.text('$_longName 11'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('$_longName 11'), findsOneWidget);
  });

  testOnScreens('recojo en tienda: vacío sin desbordes', (
    tester,
    screen,
  ) async {
    await _pump(tester, const CounterPickupScreen(), [
      storeShipmentsProvider.overrideWith((ref) async => const []),
    ]);

    expect(find.text('Sin recojos'), findsOneWidget);
  });

  testOnScreens('detalle de recepción: progreso, bultos y botón fijo', (
    tester,
    screen,
  ) async {
    await _pump(
      tester,
      ReceptionDetailScreen(args: (shipment: _shipment, node: _node)),
      [
        storeRepositoryProvider.overrideWithValue(FakeStoreRepository()),
        nodeReceptionProvider(_key).overrideWith(
          (ref) async => reception(
            status: NodeReceptionViewStatus.open,
            expected: [for (var i = 0; i < 20; i++) 'unit-long-id-$i'],
            received: const ['unit-long-id-0'],
            missing: const [],
            surplus: const ['unit-surplus-99'],
          ),
        ),
        shelfLocationsProvider.overrideWith(
          () => _PresetShelves({'unit-long-id-0': 'PASILLO 12 · ESTANTE B2'}),
        ),
      ],
    );

    _expectContentWidth(tester, screen, find.byType(CustomScrollView));
    final scan = findButtonWithText<FilledButton>('Escanear producto');
    expect(scan, findsOneWidget);
    _expectOnScreen(tester, screen, scan);

    await tester.scrollUntilVisible(
      find.text('Sobrantes (no esperados)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Sobrantes (no esperados)'), findsOneWidget);

    // La conciliación queda al final de la lista, alcanzable scrolleando.
    final reconcile = findButtonWithText<OutlinedButton>('Conciliar y cerrar');
    await tester.scrollUntilVisible(
      find.text('Conciliar y cerrar'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(reconcile, findsOneWidget);
  });

  testOnScreens('detalle de recepción: abrir recepción sin desbordes', (
    tester,
    screen,
  ) async {
    await _pump(
      tester,
      ReceptionDetailScreen(args: (shipment: _shipment, node: _node)),
      [
        storeRepositoryProvider.overrideWithValue(FakeStoreRepository()),
        nodeReceptionProvider(_key).overrideWith((ref) async => null),
        shipmentUnitsProvider(
          _shipment.id,
        ).overrideWith((ref) async => [unit(unitId: 'unit-1')]),
        storeNodesProvider.overrideWith(
          (ref) async => [
            _node,
            originNode(name: 'Centro de Distribución Santa Cruz Parque'),
          ],
        ),
      ],
    );

    await tester.scrollUntilVisible(
      findButtonWithText<FilledButton>('Abrir recepción'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(findButtonWithText<FilledButton>('Abrir recepción'), findsOneWidget);
    // Sin recepción abierta no hay botón de escaneo al pie.
    expect(findButtonWithText<FilledButton>('Escanear producto'), findsNothing);
  });

  testOnScreens('POD de recojo: datos, pasos y botón de entrega fijo', (
    tester,
    screen,
  ) async {
    await _pump(tester, PickupPodScreen(shipment: _shipment), [
      shipmentUnitsProvider(_shipment.id).overrideWith(
        (ref) async => [
          for (var i = 0; i < 6; i++)
            unit(unitId: 'unit-$i', label: 'Caja grande refrigerada $i'),
        ],
      ),
    ]);

    expect(find.text(_longName), findsOneWidget);
    _expectContentWidth(tester, screen, find.byType(CustomScrollView));
    final deliver = findButtonWithText<FilledButton>(
      'Escanear y entregar producto',
    );
    _expectOnScreen(tester, screen, deliver);

    // Al escribir la confirmación el teclado no rompe el layout.
    final field = find.widgetWithText(TextField, 'QR del cliente o documento');
    await tester.scrollUntilVisible(
      field,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.enterText(field, 'CI-1');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(deliver).onPressed, isNotNull);
  });
}

/// Ubicaciones en estante precargadas (para probar el texto extra por bulto).
class _PresetShelves extends ShelfLocationsNotifier {
  _PresetShelves(this.initial);

  final Map<String, String> initial;

  @override
  Map<String, String> build() => initial;
}
