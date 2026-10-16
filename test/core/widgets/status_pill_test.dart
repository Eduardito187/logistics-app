import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/widgets/status_pill.dart';

// Chip de estado con color semántico según PillTone. Presentacional.
Future<void> _pump(WidgetTester tester, Widget pill) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: pill)));
}

void main() {
  test('PillTone tiene los cinco tonos del contrato', () {
    expect(PillTone.values, <PillTone>[
      PillTone.neutral,
      PillTone.info,
      PillTone.success,
      PillTone.warning,
      PillTone.danger,
    ]);
  });

  testWidgets('muestra la etiqueta', (tester) async {
    await _pump(tester, const StatusPill('En ruta'));
    expect(find.text('En ruta'), findsOneWidget);
  });

  testWidgets('sin icono no renderiza Icon', (tester) async {
    await _pump(tester, const StatusPill('Pendiente'));
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('con icono lo renderiza junto a la etiqueta', (tester) async {
    await _pump(
      tester,
      const StatusPill('Entregado', tone: PillTone.success, icon: Icons.check),
    );
    expect(find.text('Entregado'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('cada tono se renderiza sin error', (tester) async {
    for (final tone in PillTone.values) {
      await _pump(tester, StatusPill(tone.name, tone: tone));
      expect(find.text(tone.name), findsOneWidget);
    }
  });
}
