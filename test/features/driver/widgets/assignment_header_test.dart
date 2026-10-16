import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/driver/presentation/widgets/assignment_header.dart';

import '../support/driver_test_support.dart';

// Cabecera de la asignación del día: solo lectura (la asigna el supervisor).

Future<void> _pump(WidgetTester tester, MyCrew crew) async {
  await pumpScoped(
    tester,
    child: Scaffold(body: AssignmentHeader(crew: crew)),
  );
}

void main() {
  testWidgets('muestra placa, chofer, ayudantes y turno', (tester) async {
    await _pump(
      tester,
      buildMyCrew(
        vehicle: buildVehicle(plate: 'XYZ-789'),
        driver: buildDriver(name: 'Ana Gómez'),
        helpers: const [
          Helpers(id: 'h1', name: 'Luis'),
          Helpers(id: 'h2', name: 'Marta'),
        ],
        shift: Shift(
          startsAt: DateTime(2026, 10, 15, 8, 0),
          endsAt: DateTime(2026, 10, 15, 17, 30),
        ),
      ),
    );

    expect(find.text('XYZ-789'), findsOneWidget);
    expect(find.text('Chofer: Ana Gómez'), findsOneWidget);
    expect(find.text('Ayudantes: Luis, Marta'), findsOneWidget);
    expect(find.text('Turno: 08:00 - 17:30'), findsOneWidget);
  });

  testWidgets('usa el id del vehículo cuando no hay placa', (tester) async {
    await _pump(
      tester,
      buildMyCrew(vehicle: buildVehicle(id: 'v-sin-placa', plate: null)),
    );
    expect(find.text('v-sin-placa'), findsOneWidget);
  });

  testWidgets('chofer sin nombre usa texto por defecto', (tester) async {
    await _pump(tester, buildMyCrew(driver: buildDriver(name: null)));
    expect(find.text('Chofer: Chofer asignado'), findsOneWidget);
  });

  testWidgets('sin ayudantes ni turno no muestra esas líneas', (tester) async {
    await _pump(tester, buildMyCrew());
    expect(find.textContaining('Ayudantes:'), findsNothing);
    expect(find.textContaining('Turno:'), findsNothing);
  });

  testWidgets('ayudantes sin nombre se filtran', (tester) async {
    await _pump(
      tester,
      buildMyCrew(
        helpers: const [
          Helpers(id: 'h1', name: null),
          Helpers(id: 'h2', name: 'Pedro'),
        ],
      ),
    );
    expect(find.text('Ayudantes: Pedro'), findsOneWidget);
  });
}
