import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/tariff_result.dart';

import '../../carrier_fixtures.dart';

// Resultado de la consulta de tarifa vigente: monto, corredor, tipo, clase y
// fecha de vigencia.

void main() {
  testWidgets('muestra monto, corredor, tipo, clase y vigencia', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TariffResult(tariff: tariff())),
      ),
    );

    expect(find.text('Tarifa vigente'), findsOneWidget);
    expect(find.textContaining('Bs'), findsOneWidget);
    expect(find.text('LPB → SCZ'), findsOneWidget);
    expect(find.text('CD → Tienda'), findsOneWidget);
    expect(find.text('Camión'), findsOneWidget);
    expect(find.textContaining('Vigente desde 2026-01-15'), findsOneWidget);
  });
}
