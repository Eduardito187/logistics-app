import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/carrier/data/repositories/carrier_repository_impl.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/tariff_form.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/tariff_result.dart';

import '../../carrier_fixtures.dart';
import '../../carrier_test_harness.dart';
import '../../../../support/button_finders.dart';

// Consulta de tarifa por corredor y clase de vehículo para el transportista
// elegido: validación, resultado y error.

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
  testWidgets('con corredor válido consulta y muestra la tarifa vigente', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeCarrierRepository(onGetTariff: () async => tariff()),
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

    expect(find.byType(TariffResult), findsOneWidget);
    expect(find.text('Tarifa vigente'), findsOneWidget);
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

  testWidgets('error de API muestra el estado de error', (tester) async {
    await _pump(
      tester,
      FakeCarrierRepository(
        onGetTariff: () async =>
            throw const ApiException(status: 500, title: 'x', detail: 'Falló'),
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
