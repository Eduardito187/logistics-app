import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/plan_status.dart';
import 'package:logistics_app/features/supervisor/presentation/widgets/plan_card.dart';

import '../../support/supervisor_fixtures.dart';

// PlanCard: camión, pastilla de estado, número de paradas y la ETA final
// (la hora más tardía entre las paradas con ETA).

void main() {
  testWidgets('muestra camión, estado, paradas y la ETA final (la más tardía)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlanCard(
            plan: plan(
              vehicleId: 'CAM-3',
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
        ),
      ),
    );

    expect(find.text('Camión CAM-3'), findsOneWidget);
    expect(find.text('Publicado'), findsOneWidget); // pastilla de estado
    expect(find.text('2 paradas'), findsOneWidget);
    // La ETA final es la hora más tardía (13:30), no la del último en la lista.
    expect(find.text('ETA final: 13:30'), findsOneWidget);
  });

  testWidgets('sin paradas con ETA muestra un guion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlanCard(
            plan: plan(stops: [plannedStop(sequence: 1, loadOrder: 1)]),
          ),
        ),
      ),
    );

    expect(find.text('1 paradas'), findsOneWidget);
    expect(find.text('ETA final: —'), findsOneWidget);
  });
}
