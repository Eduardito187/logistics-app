import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/corridor_type.dart';
import 'package:logistics_app/core/api/models/settlement.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/carrier/data/repositories/carrier_repository_impl.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/tariff_form.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/tariff_result.dart';

import '../../carrier_fixtures.dart';
import '../../carrier_test_harness.dart';
import '../../../../support/button_finders.dart';

// Consulta de tarifa para el transportista elegido: el corredor se ELIGE de la
// lista derivada de sus liquidaciones (origen, destino y tipo de una sola vez),
// con entrada manual solo si todavía no tiene ninguna.

/// Un corredor real del transportista (CD Santa Cruz → Tienda SCZ Centro).
Future<List<Settlement>> _oneCorridor(String _) async => [
  settlement(
    corridorFrom: 'cd-santa-cruz',
    corridorTo: 'store-scz-centro',
    corridorType: CorridorType.cdToStore,
  ),
];

Future<void> _pump(WidgetTester tester, FakeCarrierRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [carrierRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        home: Scaffold(body: TariffForm(carrier: carrier())),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester) async {
  final button = findButtonWithText<FilledButton>('Consultar tarifa');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('con el corredor elegido consulta y muestra la tarifa vigente', (
    tester,
  ) async {
    final repo = FakeCarrierRepository(
      onListSettlements: _oneCorridor,
      onGetTariff: () async => tariff(),
    );
    await _pump(tester, repo);

    // Un solo corredor: ya queda elegido, sin tipear códigos.
    expect(find.text('CD Santa Cruz → Tienda SCZ Centro'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await _submit(tester);

    expect(find.byType(TariffResult), findsOneWidget);
    expect(find.text('Tarifa vigente'), findsOneWidget);
    // El corredor elegido define origen, destino Y tipo.
    expect(repo.lastCorridorFrom, 'cd-santa-cruz');
    expect(repo.lastCorridorTo, 'store-scz-centro');
    expect(repo.lastCorridorType, CorridorType.cdToStore);
  });

  testWidgets('sin corredor no consulta (validación)', (tester) async {
    var called = false;
    await _pump(
      tester,
      FakeCarrierRepository(
        onGetTariff: () async {
          called = true;
          return tariff();
        },
      ),
    );

    await _submit(tester);
    expect(called, isFalse);
    expect(find.byType(TariffResult), findsNothing);
  });

  testWidgets('sin liquidaciones se puede escribir el corredor y consultar', (
    tester,
  ) async {
    final repo = FakeCarrierRepository(onGetTariff: () async => tariff());
    await _pump(tester, repo);

    expect(
      find.textContaining('Todavía no tenemos corredores tuyos'),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Origen'),
      'cd-la-paz',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Destino'),
      'cd-santa-cruz',
    );
    await _submit(tester);

    expect(find.byType(TariffResult), findsOneWidget);
    expect(repo.lastCorridorFrom, 'cd-la-paz');
    expect(repo.lastCorridorTo, 'cd-santa-cruz');
  });

  testWidgets('error de API muestra el estado de error', (tester) async {
    await _pump(
      tester,
      FakeCarrierRepository(
        onListSettlements: _oneCorridor,
        onGetTariff: () async =>
            throw const ApiException(status: 500, title: 'x', detail: 'Falló'),
      ),
    );

    await _submit(tester);

    expect(find.text('No se pudo cargar'), findsOneWidget);
  });
}
