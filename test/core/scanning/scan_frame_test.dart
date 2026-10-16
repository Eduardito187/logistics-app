import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/scanning/scan_frame.dart';

// Overlay de guía del escáner: recuadro central + texto de ayuda opcional. Es
// presentacional y no captura toques (IgnorePointer).
Future<void> _pump(WidgetTester tester, {String? helper}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Stack(children: [ScanFrame(helper: helper)]),
      ),
    ),
  );
}

void main() {
  testWidgets('dibuja el recuadro y no intercepta toques', (tester) async {
    await _pump(tester);
    expect(find.byType(IgnorePointer), findsOneWidget);

    final box = tester.widget<Container>(
      find.descendant(
        of: find.byType(IgnorePointer),
        matching: find.byType(Container),
      ),
    );
    expect(box.constraints?.maxWidth, 260);
    expect(box.constraints?.maxHeight, 260);
  });

  testWidgets('muestra el texto de ayuda cuando se provee', (tester) async {
    await _pump(tester, helper: 'Apuntá al QR de la etiqueta');
    expect(find.text('Apuntá al QR de la etiqueta'), findsOneWidget);
  });

  testWidgets('sin helper no muestra texto de ayuda', (tester) async {
    await _pump(tester);
    expect(find.byType(Text), findsNothing);
  });
}
