import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/supervisor/presentation/widgets/eta_row.dart';

import '../../support/supervisor_fixtures.dart';

// EtaRow: secuencia, envío y hora estimada de una parada.

void main() {
  testWidgets('muestra secuencia, envío y hora de ETA', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EtaRow(
            stop: stopEta(
              sequence: 2,
              shipmentId: 'SHP-7',
              etaAt: DateTime(2026, 3, 9, 14, 5),
            ),
          ),
        ),
      ),
    );

    expect(find.text('2'), findsOneWidget); // secuencia en el avatar
    expect(find.text('Envío SHP-7'), findsOneWidget);
    expect(find.text('14:05'), findsOneWidget);
  });

  testWidgets('sin etaAt muestra un guion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EtaRow(stop: stopEta(sequence: 1, shipmentId: 'SHP-1')),
        ),
      ),
    );

    expect(find.text('—'), findsOneWidget);
  });
}
