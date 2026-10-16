import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:logistics_app/core/api/models/shipment_status.dart';
import 'package:logistics_app/features/picking/presentation/widgets/order_card.dart';
import 'package:logistics_app/features/picking/presentation/widgets/shipment_status_pill.dart';

import '../../picking_test_harness.dart';

// Tarjeta de pedido de la worklist. Muestra número, cliente, cantidad de
// paquetes (= líneas) y la pastilla de estado; al tocarla navega a la
// preparación del pedido vía go_router.

Future<void> _pumpCard(
  WidgetTester tester, {
  required int lineCount,
  String externalId = 'EXT-7',
  String customerName = 'Ferretería Sur',
  ShipmentStatus status = ShipmentStatus.received,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: OrderCard(
            shipment: buildShipment(
              externalId: externalId,
              customerName: customerName,
              status: status,
              lineCount: lineCount,
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/picking/order/:orderNumber',
        builder: (_, state) => Scaffold(
          body: Text('DESTINO ${state.pathParameters['orderNumber']}'),
        ),
      ),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra pedido, cliente, estado y "1 paquete" en singular', (
    tester,
  ) async {
    await _pumpCard(tester, lineCount: 1);

    expect(find.text('Pedido EXT-7'), findsOneWidget);
    expect(find.text('Ferretería Sur'), findsOneWidget);
    expect(find.text('1 paquete'), findsOneWidget);
    expect(find.byType(ShipmentStatusPill), findsOneWidget);
    expect(find.text('Por preparar'), findsOneWidget);
  });

  testWidgets('pluraliza la cantidad de paquetes', (tester) async {
    await _pumpCard(tester, lineCount: 3, status: ShipmentStatus.planned);

    expect(find.text('3 paquetes'), findsOneWidget);
    expect(find.text('Planificado'), findsOneWidget);
  });

  testWidgets('al tocarla navega a la preparación del pedido', (tester) async {
    await _pumpCard(tester, lineCount: 2, externalId: 'EXT-42');

    await tester.tap(find.byType(OrderCard));
    await tester.pumpAndSettle();

    expect(find.text('DESTINO EXT-42'), findsOneWidget);
  });
}
