import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/widgets/stat_tile.dart';

// Mosaico de métrica: número grande + etiqueta, con ícono y color opcionales.
Future<void> _pump(WidgetTester tester, Widget w) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: w)));
}

void main() {
  testWidgets('muestra valor y etiqueta', (tester) async {
    await _pump(tester, const StatTile(value: '12', label: 'Entregas'));
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Entregas'), findsOneWidget);
  });

  testWidgets('sin icono no renderiza Icon', (tester) async {
    await _pump(tester, const StatTile(value: '0', label: 'x'));
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('con icono lo renderiza', (tester) async {
    await _pump(
      tester,
      const StatTile(
        value: '3',
        label: 'Fallidas',
        icon: Icons.warning,
        color: Colors.red,
      ),
    );
    expect(find.byIcon(Icons.warning), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}
