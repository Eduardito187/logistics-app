import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/driver/presentation/widgets/price_hint.dart';

import '../support/driver_test_support.dart';

// Ayuda con el precio de combustible vigente (loading / error / dato + Usar).

void main() {
  testWidgets('cargando muestra el aviso de consulta', (tester) async {
    await pumpScoped(
      tester,
      settle: false,
      child: Scaffold(
        body: PriceHint(value: const AsyncLoading(), onUse: (_) {}),
      ),
    );
    expect(find.text('Consultando precio vigente…'), findsOneWidget);
  });

  testWidgets('error muestra que no hay precio vigente', (tester) async {
    await pumpScoped(
      tester,
      child: Scaffold(
        body: PriceHint(
          value: AsyncError(
            const ApiException(status: 500, title: 'x'),
            StackTrace.empty,
          ),
          onUse: (_) {},
        ),
      ),
    );
    expect(find.text('Sin precio vigente disponible.'), findsOneWidget);
  });

  testWidgets('con dato muestra el precio y "Usar" devuelve los centavos', (
    tester,
  ) async {
    int? used;
    await pumpScoped(
      tester,
      child: Scaffold(
        body: PriceHint(
          value: AsyncData(buildFuelPrice(priceCents: 374)),
          onUse: (cents) => used = cents,
        ),
      ),
    );

    expect(find.text('Precio vigente: BOB 3.74 / L'), findsOneWidget);
    await tester.tap(find.text('Usar'));
    await tester.pump();
    expect(used, 374);
  });
}
