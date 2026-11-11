import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/driver/domain/usecases/conduct_checklist.dart';
import 'package:logistics_app/features/driver/presentation/checklist_screen.dart';

import '../support/driver_test_support.dart';
import '../../../support/button_finders.dart';

// Checklist pre-salida: el chofer que firma es el ASIGNADO al camión (el del
// crew), no se elige de una lista. Snackbars "apto"/"con observaciones"/error.

Future<FakeConductChecklist> _pumpChecklist(
  WidgetTester tester, {
  Data5? result,
  Object? error,
}) async {
  final fake = FakeConductChecklist(result: result, error: error);
  await pumpScoped(
    tester,
    overrides: [
      ...gateBase(),
      conductChecklistProvider.overrideWith((ref) => fake),
    ],
    child: const ChecklistScreen(),
    tall: true,
  );
  return fake;
}

void main() {
  testWidgets('no pide elegir chofer: el botón está habilitado de entrada', (
    tester,
  ) async {
    await _pumpChecklist(tester, result: const Data5(status: 'ok'));

    // Ya no hay dropdown de "Selecciona el chofer".
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    final button = tester.widget<FilledButton>(
      findButtonWithText<FilledButton>('Registrar checklist'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('firma con el chofer ASIGNADO del crew (no se elige)', (
    tester,
  ) async {
    final fake = await _pumpChecklist(
      tester,
      result: const Data5(status: 'ok'),
    );

    await tester.tap(find.text('Registrar checklist'));
    await tester.pump();
    await tester.pump();

    // El crew por defecto tiene el chofer con id 'd1' (buildDriver).
    expect(fake.lastDriverId, 'd1');
  });

  testWidgets('todo marcado => "apto para salir" (verde)', (tester) async {
    await _pumpChecklist(tester, result: const Data5(status: 'ok'));

    final switches = find.byType(SwitchListTile);
    for (var i = 0; i < switches.evaluate().length; i++) {
      await tester.tap(switches.at(i));
      await tester.pump();
    }

    await tester.tap(find.text('Registrar checklist'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Checklist registrado: apto para salir.'), findsOneWidget);
  });

  testWidgets('observación NO crítica => "con observaciones" y el status', (
    tester,
  ) async {
    await _pumpChecklist(tester, result: const Data5(status: 'needs_review'));

    // Se marca todo y se desmarca un ítem NO crítico (extintor): queda "con
    // observaciones", no "no apto".
    final switches = find.byType(SwitchListTile);
    for (var i = 0; i < switches.evaluate().length; i++) {
      await tester.tap(switches.at(i));
      await tester.pump();
    }
    await tester.tap(find.widgetWithText(SwitchListTile, 'Extintor'));
    await tester.pump();

    await tester.tap(find.text('Registrar checklist'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Checklist registrado con observaciones (needs_review).'),
      findsOneWidget,
    );
  });

  testWidgets('ítem CRÍTICO falla (frenos) => "NO apto para salir" en rojo', (
    tester,
  ) async {
    await _pumpChecklist(tester, result: const Data5(status: 'needs_review'));

    // Todo marcado menos FRENOS (crítico) → no apto.
    final switches = find.byType(SwitchListTile);
    for (var i = 0; i < switches.evaluate().length; i++) {
      await tester.tap(switches.at(i));
      await tester.pump();
    }
    await tester.tap(find.widgetWithText(SwitchListTile, 'Frenos'));
    await tester.pump();

    await tester.tap(find.text('Registrar checklist'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('NO apto para salir'), findsOneWidget);
    expect(find.textContaining('Frenos'), findsWidgets);
  });

  testWidgets('error de API muestra el mensaje de la excepción', (
    tester,
  ) async {
    await _pumpChecklist(
      tester,
      error: const ApiException(status: 500, title: 'x'),
    );

    await tester.tap(find.text('Registrar checklist'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Error del servidor. Probá de nuevo en un momento.'),
      findsOneWidget,
    );
  });
}
