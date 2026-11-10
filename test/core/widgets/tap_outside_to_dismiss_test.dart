import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/widgets/tap_outside_to_dismiss.dart';

// Tocar el área de afuera (scrim) cierra; tocar la tarjeta no.

Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const TapOutsideToDismiss(
                  child: SizedBox(
                    height: 160,
                    width: 300,
                    child: Material(child: Center(child: Text('TARJETA'))),
                  ),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  expect(find.text('TARJETA'), findsOneWidget);
}

void main() {
  testWidgets('tocar el área de afuera (arriba) cierra el sheet', (
    tester,
  ) async {
    await _open(tester);

    // Toca bien arriba, lejos de la tarjeta (que está abajo): es el scrim.
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();

    expect(find.text('TARJETA'), findsNothing); // se cerró
  });

  testWidgets('tocar la tarjeta NO cierra el sheet', (tester) async {
    await _open(tester);

    await tester.tap(find.text('TARJETA'));
    await tester.pumpAndSettle();

    expect(find.text('TARJETA'), findsOneWidget); // sigue abierto
  });
}
