import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:logistics_app/core/api/models/plan.dart';
import 'package:logistics_app/core/api/models/plan_status.dart';
import 'package:logistics_app/features/supervisor/presentation/controllers/supervisor_controllers.dart';
import 'package:logistics_app/features/supervisor/presentation/widgets/plan_card.dart';

import '../../support/supervisor_fixtures.dart';

// PlanCard: camión (por placa), pastilla de estado, número de paradas y la ETA
// final (la hora más tardía entre las paradas con ETA).

Future<void> _pump(
  WidgetTester tester,
  Widget card, {
  Map<String, String> plates = const {},
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [vehiclePlatesProvider.overrideWith((ref) async => plates)],
      child: MaterialApp(home: Scaffold(body: card)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra la placa, estado, paradas y la ETA final', (
    tester,
  ) async {
    await _pump(
      tester,
      PlanCard(
        plan: plan(
          vehicleId: '01a137b3-049a-756f-bfae-d3aa1be6d47c',
          status: PlanStatus.published,
          stops: [
            plannedStop(
              sequence: 1,
              loadOrder: 2,
              etaAt: DateTime(2026, 3, 9, 10, 0),
            ),
            plannedStop(
              sequence: 2,
              loadOrder: 1,
              etaAt: DateTime(2026, 3, 9, 13, 30),
            ),
          ],
        ),
      ),
      plates: {'01a137b3-049a-756f-bfae-d3aa1be6d47c': '904U10'},
    );

    expect(find.text('Camión 904U10'), findsOneWidget);
    expect(find.textContaining('01a137b3'), findsNothing); // nunca el UUID
    expect(find.text('Publicado'), findsOneWidget); // pastilla de estado
    expect(find.text('2 paradas'), findsOneWidget);
    // La ETA final es la hora más tardía (13:30), no la del último en la lista.
    expect(find.text('ETA final: 13:30'), findsOneWidget);
  });

  testWidgets('sin placa muestra el id abreviado, no el UUID entero', (
    tester,
  ) async {
    await _pump(
      tester,
      PlanCard(plan: plan(vehicleId: '01a137b3-049a-756f-bfae-d3aa1be6d47c')),
    );

    expect(find.text('Camión …e6d47c'), findsOneWidget);
  });

  testWidgets('sin paradas con ETA muestra un guion', (tester) async {
    await _pump(
      tester,
      PlanCard(plan: plan(stops: [plannedStop(sequence: 1, loadOrder: 1)])),
    );

    expect(find.text('1 paradas'), findsOneWidget);
    expect(find.text('ETA final: —'), findsOneWidget);
  });

  testWidgets(
    'tocar la tarjeta abre el detalle del plan con el plan de la lista',
    (tester) async {
      Object? receivedExtra;
      String? receivedId;
      final listed = plan(id: 'p42');
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(body: PlanCard(plan: listed)),
          ),
          GoRoute(
            path: '/supervisor/plans/:planId',
            builder: (context, state) {
              receivedId = state.pathParameters['planId'];
              receivedExtra = state.extra;
              return const Scaffold(body: Text('detalle'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [vehiclePlatesProvider.overrideWith((ref) async => {})],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PlanCard));
      await tester.pumpAndSettle();

      expect(find.text('detalle'), findsOneWidget);
      expect(receivedId, 'p42');
      expect(receivedExtra, isA<Plan>());
    },
  );
}
