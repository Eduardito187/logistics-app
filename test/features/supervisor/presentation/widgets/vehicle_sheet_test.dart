import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/vehicle_live.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/supervisor/data/repositories/supervisor_repository_impl.dart';
import 'package:logistics_app/features/supervisor/presentation/widgets/vehicle_sheet.dart';

import '../../support/fake_supervisor_repository.dart';
import '../../support/supervisor_fixtures.dart';

// VehicleSheet.show: hoja inferior con el detalle del camión y su resumen de
// telemetría del día (cargado vía vehicleSummaryProvider).

Future<void> _open(
  WidgetTester tester,
  FakeSupervisorRepository repo, {
  required VehicleLive vehicle,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [supervisorRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => VehicleSheet.show(context, vehicle),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra datos del camión y el resumen del día', (tester) async {
    final repo = FakeSupervisorRepository()
      ..vehicleSummaryValue = vehicleSummary(
        vehicleId: 'CAM-1',
        distanceM: 12500,
        trips: 3,
        maxSpeedKph: 82.4,
      );

    await _open(
      tester,
      repo,
      vehicle: vehicleLive(
        vehicleId: 'CAM-1',
        moving: true,
        speedKph: 45,
        recordedAt: DateTime(2026, 3, 9, 9, 15),
      ),
    );

    expect(find.text('Camión CAM-1'), findsOneWidget);
    expect(find.text('En movimiento'), findsOneWidget); // pastilla
    expect(find.text('Última lectura: 09:15'), findsOneWidget);
    expect(find.text('Velocidad: 45 km/h'), findsOneWidget);
    // Resumen del día.
    expect(find.text('Resumen del día'), findsOneWidget);
    expect(find.text('Distancia: 12.5 km'), findsOneWidget);
    expect(find.text('Viajes: 3'), findsOneWidget);
    expect(find.text('Velocidad máx: 82 km/h'), findsOneWidget);
  });

  testWidgets('camión detenido y sin velocidad omite la línea de velocidad', (
    tester,
  ) async {
    final repo = FakeSupervisorRepository()
      ..vehicleSummaryValue = vehicleSummary();

    await _open(tester, repo, vehicle: vehicleLive(moving: false));

    expect(find.text('Detenido'), findsOneWidget);
    expect(find.textContaining('Velocidad: '), findsNothing);
  });

  testWidgets('si el resumen falla, la hoja muestra el error con reintento', (
    tester,
  ) async {
    final repo = FakeSupervisorRepository()
      ..vehicleSummaryError = const ApiException(status: 500, title: 'x');

    await _open(tester, repo, vehicle: vehicleLive(vehicleId: 'CAM-1'));

    // La cabecera del camión sigue visible...
    expect(find.text('Camión CAM-1'), findsOneWidget);
    // ...y el error aparece en el lugar del resumen.
    expect(find.text('No se pudo cargar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
