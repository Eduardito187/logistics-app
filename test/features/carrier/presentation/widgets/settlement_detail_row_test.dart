import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/settlement_detail_row.dart';

// Fila etiqueta/valor del detalle de liquidación.

void main() {
  testWidgets('muestra la etiqueta y el valor', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SettlementDetailRow(label: 'Periodo', value: '2026-03'),
        ),
      ),
    );

    expect(find.text('Periodo'), findsOneWidget);
    expect(find.text('2026-03'), findsOneWidget);
  });
}
