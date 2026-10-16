import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/supervisor/presentation/widgets/detail_row.dart';

// DetailRow: fila etiqueta/valor de la cabecera de un plan.

void main() {
  testWidgets('muestra etiqueta y valor', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DetailRow(label: 'Fecha', value: '09/03/2026'),
        ),
      ),
    );

    expect(find.text('Fecha'), findsOneWidget);
    expect(find.text('09/03/2026'), findsOneWidget);
  });
}
