import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/driver/presentation/widgets/route_list.dart';
import 'package:logistics_app/features/driver/presentation/widgets/stop_card.dart';

import '../support/driver_test_support.dart';

// Lista de paradas ordenadas por secuencia.

void main() {
  testWidgets('ordena las paradas por secuencia ascendente', (tester) async {
    await pumpScoped(
      tester,
      child: Scaffold(
        body: RouteList(
          route: buildRoute(
            totalStops: 3,
            stops: [
              buildStop(id: 'c', sequence: 3, customerName: 'Tercera'),
              buildStop(id: 'a', sequence: 1, customerName: 'Primera'),
              buildStop(id: 'b', sequence: 2, customerName: 'Segunda'),
            ],
          ),
        ),
      ),
    );

    final cards = tester.widgetList<StopCard>(find.byType(StopCard)).toList();
    expect(cards.map((c) => c.stop.sequence).toList(), [1, 2, 3]);
  });

  testWidgets('renderiza una tarjeta por parada', (tester) async {
    await pumpScoped(
      tester,
      child: Scaffold(
        body: RouteList(
          route: buildRoute(
            totalStops: 2,
            stops: [
              buildStop(id: 'a', sequence: 1),
              buildStop(id: 'b', sequence: 2),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(StopCard), findsNWidgets(2));
  });
}
