import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/cheapest_tariff_result.dart';

import '../../carrier_fixtures.dart';

// Resultado de la tarifa más barata: incluye el nombre del transportista.

void main() {
  testWidgets('muestra transportista, corredor, clase y vigencia', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CheapestTariffResult(tariff: tariff())),
      ),
    );

    expect(find.text('Tarifa más barata'), findsOneWidget);
    expect(find.text('Transportes Andinos'), findsOneWidget);
    expect(find.text('LPB → SCZ'), findsOneWidget);
    expect(find.text('CD → Tienda'), findsOneWidget);
    expect(find.text('Camión'), findsOneWidget);
    expect(find.textContaining('Vigente desde 2026-01-15'), findsOneWidget);
  });

  testWidgets('sin nombre de transportista omite esa línea', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CheapestTariffResult(tariff: tariff(carrierName: null)),
        ),
      ),
    );

    expect(find.text('Transportes Andinos'), findsNothing);
    expect(find.text('LPB → SCZ'), findsOneWidget);
  });
}
