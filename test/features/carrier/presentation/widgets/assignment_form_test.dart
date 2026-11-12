import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/corridor_type.dart';
import 'package:logistics_app/core/api/models/settlement.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/carrier/data/repositories/carrier_repository_impl.dart';
import 'package:logistics_app/features/carrier/presentation/controllers/carrier_controllers.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/assignment_form.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/assignment_result.dart';

import '../../carrier_fixtures.dart';
import '../../carrier_test_harness.dart';
import '../../../../support/button_finders.dart';

// Asignación por volumen: corredor elegido de la lista del transportista (o
// escrito si todavía no tiene liquidaciones) + volumen > 0.

Future<List<Settlement>> _oneCorridor(String _) async => [
  settlement(
    corridorFrom: 'cd-santa-cruz',
    corridorTo: 'store-scz-centro',
    corridorType: CorridorType.cdToStore,
  ),
];

Future<void> _pump(
  WidgetTester tester,
  FakeCarrierRepository repo, {
  bool withCarrier = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [carrierRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: Scaffold(body: AssignmentForm())),
    ),
  );
  if (withCarrier) {
    ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    ).read(selectedCarrierProvider.notifier).select(carrier());
  }
  await tester.pumpAndSettle();
}

Future<void> _enterVolume(WidgetTester tester, String volume) =>
    tester.enterText(find.widgetWithText(TextField, 'Volumen (m³)'), volume);

Future<void> _submit(WidgetTester tester) async {
  final button = findButtonWithText<FilledButton>('Calcular asignación');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('con corredor elegido y volumen válido muestra el resultado', (
    tester,
  ) async {
    final repo = FakeCarrierRepository(
      onListSettlements: _oneCorridor,
      onAssignForVolume: () async => assignment(tariffValue: tariff()),
    );
    await _pump(tester, repo, withCarrier: true);

    expect(find.text('CD Santa Cruz → Tienda SCZ Centro'), findsOneWidget);
    await _enterVolume(tester, '12.5');
    await _submit(tester);

    expect(find.byType(AssignmentResult), findsOneWidget);
    expect(find.text('Vehículo sugerido'), findsOneWidget);
    expect(find.text('Camión'), findsOneWidget);
    expect(repo.lastCorridorFrom, 'cd-santa-cruz');
    expect(repo.lastCorridorType, CorridorType.cdToStore);
  });

  testWidgets('sin corredor ni volumen no consulta (validación)', (
    tester,
  ) async {
    var called = false;
    await _pump(
      tester,
      FakeCarrierRepository(
        onAssignForVolume: () async {
          called = true;
          return assignment();
        },
      ),
    );

    await _submit(tester);

    expect(called, isFalse);
    expect(find.byType(AssignmentResult), findsNothing);
  });

  testWidgets('con corredor pero volumen cero no consulta', (tester) async {
    var called = false;
    await _pump(
      tester,
      FakeCarrierRepository(
        onListSettlements: _oneCorridor,
        onAssignForVolume: () async {
          called = true;
          return assignment();
        },
      ),
      withCarrier: true,
    );

    await _enterVolume(tester, '0');
    await _submit(tester);

    expect(called, isFalse);
  });

  testWidgets('asignación sin tarifa muestra el aviso', (tester) async {
    await _pump(
      tester,
      FakeCarrierRepository(
        onListSettlements: _oneCorridor,
        onAssignForVolume: () async => assignment(),
      ),
      withCarrier: true,
    );

    await _enterVolume(tester, '12.5');
    await _submit(tester);

    expect(
      find.text('No hay tarifa registrada para esta clase en el corredor.'),
      findsOneWidget,
    );
  });

  testWidgets('error de API muestra el estado de error', (tester) async {
    await _pump(
      tester,
      FakeCarrierRepository(
        onListSettlements: _oneCorridor,
        onAssignForVolume: () async =>
            throw const ApiException(status: 500, title: 'x', detail: 'Falló'),
      ),
      withCarrier: true,
    );

    await _enterVolume(tester, '12.5');
    await _submit(tester);

    expect(find.text('No se pudo cargar'), findsOneWidget);
  });
}
