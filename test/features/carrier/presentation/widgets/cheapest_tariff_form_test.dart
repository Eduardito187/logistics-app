import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/carrier/data/repositories/carrier_repository_impl.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/cheapest_tariff_form.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/cheapest_tariff_result.dart';

import '../../carrier_fixtures.dart';
import '../../carrier_test_harness.dart';

// Tarifa más barata: validación (corredor requerido), resultado y error.

Future<void> _pump(WidgetTester tester, FakeCarrierRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [carrierRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: Scaffold(body: CheapestTariffForm())),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, 'Buscar más barata');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('con corredor válido consulta y muestra el resultado', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeCarrierRepository(onCheapestTariff: () async => tariff()),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Origen (código)'),
      'LPB',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Destino (código)'),
      'SCZ',
    );
    await _submit(tester);

    expect(find.byType(CheapestTariffResult), findsOneWidget);
    expect(find.text('LPB → SCZ'), findsOneWidget);
  });

  testWidgets('sin corredor no consulta (validación)', (tester) async {
    var called = false;
    await _pump(
      tester,
      FakeCarrierRepository(
        onCheapestTariff: () async {
          called = true;
          return tariff();
        },
      ),
    );

    await _submit(tester);
    expect(called, isFalse);
    expect(find.byType(CheapestTariffResult), findsNothing);
  });

  testWidgets('error de API muestra el estado de error', (tester) async {
    await _pump(
      tester,
      FakeCarrierRepository(
        onCheapestTariff: () async =>
            throw const ApiException(status: 404, title: 'x', detail: 'Nada'),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Origen (código)'),
      'LPB',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Destino (código)'),
      'SCZ',
    );
    await _submit(tester);

    expect(find.text('No se pudo cargar'), findsOneWidget);
  });
}
