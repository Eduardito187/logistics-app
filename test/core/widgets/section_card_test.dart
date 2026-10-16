import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/widgets/section_card.dart';

// Tarjeta estándar: título opcional, trailing opcional y onTap opcional.
Future<void> _pump(WidgetTester tester, Widget card) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: card)));
}

void main() {
  testWidgets('muestra el child', (tester) async {
    await _pump(tester, const SectionCard(child: Text('contenido')));
    expect(find.text('contenido'), findsOneWidget);
  });

  testWidgets('muestra título y trailing cuando se proveen', (tester) async {
    await _pump(
      tester,
      const SectionCard(
        title: 'Resumen',
        trailing: Icon(Icons.more_horiz),
        child: Text('cuerpo'),
      ),
    );
    expect(find.text('Resumen'), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);
  });

  testWidgets('sin título no muestra encabezado', (tester) async {
    await _pump(tester, const SectionCard(child: Text('solo cuerpo')));
    // Único Text visible es el cuerpo.
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('onTap se dispara al tocar la tarjeta', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      SectionCard(onTap: () => taps++, child: const Text('tocar')),
    );
    await tester.tap(find.text('tocar'));
    await tester.pump();
    expect(taps, 1);
  });
}
