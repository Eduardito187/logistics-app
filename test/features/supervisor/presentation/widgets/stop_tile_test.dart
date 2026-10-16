import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/supervisor/presentation/widgets/stop_tile.dart';

import '../../support/supervisor_fixtures.dart';

// StopTile: fila de parada de solo lectura. El subtítulo concatena carga, carril
// (si hay) y minutos de ETA (si hay) separados por ' · '.

void main() {
  testWidgets('muestra posición, envío y el subtítulo completo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StopTile(
            position: 3,
            stop: plannedStop(
              sequence: 3,
              loadOrder: 5,
              shipmentId: 'SHP-9',
              lane: 'A2',
              etaMinutes: 42,
            ),
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget); // posición en el avatar
    expect(find.text('Envío SHP-9'), findsOneWidget);
    expect(find.text('Carga #5 · Carril A2 · 42 min'), findsOneWidget);
  });

  testWidgets('omite carril y minutos cuando son null', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StopTile(
            position: 1,
            stop: plannedStop(sequence: 1, loadOrder: 2, shipmentId: 'SHP-1'),
          ),
        ),
      ),
    );

    expect(find.text('Carga #2'), findsOneWidget);
  });
}
