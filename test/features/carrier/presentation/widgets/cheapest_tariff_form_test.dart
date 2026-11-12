import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/corridor_type.dart';
import 'package:logistics_app/core/api/models/settlement.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/carrier/data/repositories/carrier_repository_impl.dart';
import 'package:logistics_app/features/carrier/presentation/controllers/carrier_controllers.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/cheapest_tariff_form.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/cheapest_tariff_result.dart';

import '../../carrier_fixtures.dart';
import '../../carrier_test_harness.dart';
import '../../../../support/button_finders.dart';

// Tarifa más barata: el corredor se elige de la lista del transportista de la
// sesión (la tarifa sí se busca entre todos), con entrada manual de respaldo.

Future<List<Settlement>> _oneCorridor(String _) async => [
  settlement(
    corridorFrom: 'cd-santa-cruz',
    corridorTo: 'store-scz-centro',
    corridorType: CorridorType.cdToStore,
  ),
];

/// Monta el formulario; con [withCarrier] deja un transportista elegido (de ahí
/// salen sus corredores).
Future<void> _pump(
  WidgetTester tester,
  FakeCarrierRepository repo, {
  bool withCarrier = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [carrierRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: Scaffold(body: CheapestTariffForm())),
    ),
  );
  if (withCarrier) {
    ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    ).read(selectedCarrierProvider.notifier).select(carrier());
  }
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester) async {
  final button = findButtonWithText<FilledButton>('Buscar más barata');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('con el corredor elegido busca y muestra el resultado', (
    tester,
  ) async {
    final repo = FakeCarrierRepository(
      onListSettlements: _oneCorridor,
      onCheapestTariff: () async => tariff(),
    );
    await _pump(tester, repo, withCarrier: true);

    expect(find.text('CD Santa Cruz → Tienda SCZ Centro'), findsOneWidget);
    await _submit(tester);

    expect(find.byType(CheapestTariffResult), findsOneWidget);
    expect(find.text('LPB → SCZ'), findsOneWidget);
    expect(repo.lastCorridorFrom, 'cd-santa-cruz');
    expect(repo.lastCorridorType, CorridorType.cdToStore);
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

  testWidgets('sin transportista elegido ofrece escribir el corredor', (
    tester,
  ) async {
    final repo = FakeCarrierRepository(onCheapestTariff: () async => tariff());
    await _pump(tester, repo);

    expect(find.textContaining('Elegí tu transportista'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Origen'),
      'cd-la-paz',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Destino'),
      'cd-santa-cruz',
    );
    await _submit(tester);

    expect(find.byType(CheapestTariffResult), findsOneWidget);
    expect(repo.lastCorridorFrom, 'cd-la-paz');
  });

  testWidgets('error de API muestra el estado de error', (tester) async {
    await _pump(
      tester,
      FakeCarrierRepository(
        onListSettlements: _oneCorridor,
        onCheapestTariff: () async =>
            throw const ApiException(status: 404, title: 'x', detail: 'Nada'),
      ),
      withCarrier: true,
    );

    await _submit(tester);

    expect(find.text('No se pudo cargar'), findsOneWidget);
  });
}
