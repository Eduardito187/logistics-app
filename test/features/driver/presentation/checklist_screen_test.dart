import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/driver/domain/usecases/conduct_checklist.dart';
import 'package:logistics_app/features/driver/presentation/checklist_screen.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';

import '../support/driver_test_support.dart';

// Checklist pre-salida: snackbar "apto" cuando pasa todo, "con observaciones"
// cuando falta algún ítem, y error de API.

Future<void> _pumpChecklist(
  WidgetTester tester, {
  List<Driver> drivers = const [],
  Data4? result,
  Object? error,
}) async {
  await pumpScoped(
    tester,
    overrides: [
      ...gateBase(),
      driversProvider.overrideWith((ref) async => drivers),
      conductChecklistProvider.overrideWith(
        (ref) => FakeConductChecklist(result: result, error: error),
      ),
    ],
    child: const ChecklistScreen(),
    tall: true,
  );
}

Future<void> _selectDriver(WidgetTester tester, String name) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sin choferes activos bloquea con estado vacío', (tester) async {
    await _pumpChecklist(tester, drivers: const []);
    expect(find.text('Sin choferes'), findsOneWidget);
    expect(
      find.text('No hay choferes activos para firmar el checklist.'),
      findsOneWidget,
    );
  });

  testWidgets('todo marcado => "apto para salir" (verde)', (tester) async {
    await _pumpChecklist(
      tester,
      drivers: [buildDriver(name: 'Juan Pérez')],
      result: const Data4(status: 'ok'),
    );

    await _selectDriver(tester, 'Juan Pérez');

    // Marcar todos los ítems del checklist.
    final switches = find.byType(SwitchListTile);
    for (var i = 0; i < switches.evaluate().length; i++) {
      await tester.tap(switches.at(i));
      await tester.pump();
    }

    await tester.tap(find.text('Registrar checklist'));
    await tester.pump(); // ejecuta el submit async
    await tester.pump(); // renderiza el snackbar
    await tester.pump();

    expect(find.text('Checklist registrado: apto para salir.'), findsOneWidget);
  });

  testWidgets('con ítems sin marcar => "con observaciones" y el status', (
    tester,
  ) async {
    await _pumpChecklist(
      tester,
      drivers: [buildDriver(name: 'Ana Gómez')],
      result: const Data4(status: 'needs_review'),
    );

    await _selectDriver(tester, 'Ana Gómez');

    // No se marca ningún ítem (quedan observaciones).
    await tester.tap(find.text('Registrar checklist'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Checklist registrado con observaciones (needs_review).'),
      findsOneWidget,
    );
  });

  testWidgets('error de API muestra el mensaje de la excepción', (
    tester,
  ) async {
    await _pumpChecklist(
      tester,
      drivers: [buildDriver(name: 'Ana Gómez')],
      error: const ApiException(status: 500, title: 'x'),
    );

    await _selectDriver(tester, 'Ana Gómez');
    await tester.tap(find.text('Registrar checklist'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Error del servidor. Probá de nuevo en un momento.'),
      findsOneWidget,
    );
  });

  testWidgets('el botón se habilita solo tras elegir chofer', (tester) async {
    await _pumpChecklist(
      tester,
      drivers: [buildDriver(name: 'Juan Pérez')],
      result: const Data4(status: 'ok'),
    );

    // Sin chofer elegido el botón está deshabilitado.
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Registrar checklist'),
    );
    expect(button.onPressed, isNull);

    await _selectDriver(tester, 'Juan Pérez');
    final enabled = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Registrar checklist'),
    );
    expect(enabled.onPressed, isNotNull);
  });
}
