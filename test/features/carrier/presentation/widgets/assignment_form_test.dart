import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/carrier/data/repositories/carrier_repository_impl.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/assignment_form.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/assignment_result.dart';

import '../../carrier_fixtures.dart';
import '../../carrier_test_harness.dart';
import '../../../../support/button_finders.dart';

// Asignación por volumen: validación del formulario (corredor + volumen > 0),
// resultado con tarifa, resultado sin tarifa y error de API.

Future<void> _pump(WidgetTester tester, FakeCarrierRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [carrierRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: Scaffold(body: AssignmentForm())),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fill(
  WidgetTester tester, {
  String from = 'LPB',
  String to = 'SCZ',
  String volume = '12.5',
}) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'Origen (código)'),
    from,
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Destino (código)'),
    to,
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Volumen (m³)'),
    volume,
  );
}

Future<void> _submit(WidgetTester tester) async {
  final button = findButtonWithText<FilledButton>('Calcular asignación');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('con datos válidos consulta y muestra el resultado', (
    tester,
  ) async {
    var called = false;
    await _pump(
      tester,
      FakeCarrierRepository(
        onAssignForVolume: () async {
          called = true;
          return assignment(tariffValue: tariff());
        },
      ),
    );

    await _fill(tester);
    await _submit(tester);

    expect(called, isTrue);
    expect(find.byType(AssignmentResult), findsOneWidget);
    expect(find.text('Vehículo sugerido'), findsOneWidget);
    expect(find.text('Camión'), findsOneWidget);
  });

  testWidgets('sin corredor/volumen no consulta (validación)', (tester) async {
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

    // Botón sin llenar nada.
    await _submit(tester);

    expect(called, isFalse);
    expect(find.byType(AssignmentResult), findsNothing);
  });

  testWidgets('volumen cero o negativo no consulta', (tester) async {
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

    await _fill(tester, volume: '0');
    await _submit(tester);

    expect(called, isFalse);
  });

  testWidgets('asignación sin tarifa muestra el aviso', (tester) async {
    await _pump(
      tester,
      FakeCarrierRepository(onAssignForVolume: () async => assignment()),
    );

    await _fill(tester);
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
        onAssignForVolume: () async =>
            throw const ApiException(status: 500, title: 'x', detail: 'Falló'),
      ),
    );

    await _fill(tester);
    await _submit(tester);

    expect(find.text('No se pudo cargar'), findsOneWidget);
  });
}
