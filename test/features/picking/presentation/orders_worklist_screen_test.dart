import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/shipment.dart';
import 'package:logistics_app/core/api/models/shipment_status.dart';
import 'package:logistics_app/core/icons/icons.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/widgets/empty_state.dart';
import 'package:logistics_app/features/picking/presentation/controllers/locally_assigned_orders.dart';
import 'package:logistics_app/features/picking/presentation/orders_worklist_screen.dart';
import 'package:logistics_app/features/picking/presentation/widgets/order_card.dart';

import '../../../support/app_icon_finders.dart';
import 'package:logistics_app/features/picking/data/repositories/picking_repository_impl.dart';

import '../picking_test_harness.dart';

// Worklist del preparador. Se override el provider de datos (ordersToPrepare)
// con lista/vacío/error, y el SyncBadge con overrides que evitan Drift y el
// plugin de conectividad. La navegación usa go_router con rutas señuelo.

Future<void> _pump(
  WidgetTester tester,
  Future<List<Shipment>> Function() load,
) async {
  final router = GoRouter(
    initialLocation: '/picking/orders',
    routes: [
      GoRoute(
        path: '/picking/orders',
        builder: (_, _) => const OrdersWorklistScreen(),
      ),
      GoRoute(
        path: '/picking/order/:orderNumber',
        builder: (_, state) => Scaffold(
          body: Text('ORDEN ${state.pathParameters['orderNumber']}'),
        ),
      ),
      GoRoute(
        path: '/picking/prepare',
        builder: (_, _) => const Scaffold(body: Text('INGRESO MANUAL')),
      ),
      GoRoute(
        path: '/sync',
        builder: (_, _) => const Scaffold(body: Text('SYNC')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...syncBadgeOverrides(),
        // La pantalla usa `ordersWorklistProvider`, que se arma desde el caso
        // de uso: se siembra el repositorio para que la tanda traiga `load()`.
        pickingRepositoryProvider.overrideWithValue(
          FakePickingRepository(onListShipments: load),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('con datos lista una tarjeta por pedido', (tester) async {
    await _pump(
      tester,
      () async => [
        buildShipment(externalId: 'EXT-1', status: ShipmentStatus.received),
        buildShipment(externalId: 'EXT-2', status: ShipmentStatus.planned),
      ],
    );

    expect(find.text('Pedidos por preparar'), findsOneWidget); // AppBar
    expect(find.byType(OrderCard), findsNWidgets(2));
    expect(find.text('Pedido EXT-1'), findsOneWidget);
    expect(find.text('Pedido EXT-2'), findsOneWidget);
  });

  testWidgets(
    'oculta el pedido ASIGNADO localmente (no reaparece aunque siga PLANNED)',
    (tester) async {
      // El backend sigue devolviendo EXT-1 como PLANNED tras asignarlo, pero la
      // worklist lo oculta en cuanto se marca asignado (offline-invisible).
      await _pump(
        tester,
        () async => [
          buildShipment(externalId: 'EXT-1', status: ShipmentStatus.planned),
          buildShipment(externalId: 'EXT-2', status: ShipmentStatus.planned),
        ],
      );
      expect(find.byType(OrderCard), findsNWidgets(2));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(OrdersWorklistScreen)),
      );
      container
          .read(locallyAssignedOrdersProvider.notifier)
          .markAssigned('EXT-1');
      await tester.pumpAndSettle();

      // EXT-1 desapareció; EXT-2 sigue. La lista disminuyó.
      expect(find.byType(OrderCard), findsOneWidget);
      expect(find.text('Pedido EXT-1'), findsNothing);
      expect(find.text('Pedido EXT-2'), findsOneWidget);
    },
  );

  testWidgets('sin pedidos muestra el EmptyState', (tester) async {
    await _pump(tester, () async => const <Shipment>[]);

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('No hay pedidos por preparar'), findsOneWidget);
    expect(find.byType(OrderCard), findsNothing);
  });

  testWidgets('en error muestra "No se pudo cargar" con Reintentar', (
    tester,
  ) async {
    await _pump(
      tester,
      () async => throw const ApiException(status: 500, title: 'Boom'),
    );

    expect(find.text('No se pudo cargar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('al tocar una tarjeta navega a la preparación del pedido', (
    tester,
  ) async {
    await _pump(tester, () async => [buildShipment(externalId: 'EXT-9')]);

    await tester.tap(find.byType(OrderCard));
    await tester.pumpAndSettle();

    expect(find.text('ORDEN EXT-9'), findsOneWidget);
  });

  testWidgets('el ícono de teclado abre el ingreso manual', (tester) async {
    await _pump(tester, () async => const <Shipment>[]);

    await tester.tap(findAppIcon(AppIcon.keyboard));
    await tester.pumpAndSettle();

    expect(find.text('INGRESO MANUAL'), findsOneWidget);
  });
}
