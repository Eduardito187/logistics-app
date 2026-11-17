import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/location/truck_tracking_service.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/widgets/brand_loader.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';
import 'package:logistics_app/features/driver/presentation/driver_vehicle_gate.dart';
import 'package:logistics_app/features/driver/presentation/widgets/assignment_header.dart';
import 'package:logistics_app/features/driver/presentation/widgets/no_assignment.dart';

import '../support/driver_test_support.dart';

// El gate del chofer: SIN asignación bloquea; CON asignación deja operar con el
// vehículo ASIGNADO (el chofer no elige vehículo).

DriverVehicleGate _gate() => DriverVehicleGate(
  title: 'Operación',
  builder: (context, vehicleId) => Center(child: Text('VEH=$vehicleId')),
);

void main() {
  testWidgets('mientras carga la asignación muestra un spinner', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      settle: false,
      overrides: [
        locationServiceProvider.overrideWithValue(FakeLocationService()),
        truckTrackingProvider.overrideWith(FakeTruckTracking.new),
        driverRouteProvider.overrideWith((ref) async => buildEmptyRoute()),
        myCrewProvider.overrideWith((ref) => Completer<MyCrew>().future),
      ],
      child: _gate(),
    );

    expect(find.byType(BrandLoader), findsOneWidget);
    expect(find.byType(AssignmentHeader), findsNothing);
  });

  testWidgets('CON asignación muestra la cabecera y opera con el vehículo', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      overrides: gateBase(
        crew: buildMyCrew(
          vehicle: buildVehicle(id: 'v-7', plate: 'PLACA-7'),
        ),
      ),
      child: _gate(),
    );

    // Cabecera de asignación (solo lectura).
    expect(find.byType(AssignmentHeader), findsOneWidget);
    expect(find.text('PLACA-7'), findsOneWidget);
    // El contenido se arma con el id del vehículo ASIGNADO.
    expect(find.text('VEH=v-7'), findsOneWidget);
    // El chofer NO elige vehículo: no hay selector (dropdown) en el gate.
    expect(find.byType(DropdownButton<Object?>), findsNothing);
    expect(find.byType(NoAssignment), findsNothing);
  });

  testWidgets('SIN asignación (404) bloquea con la pantalla de contacto', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      overrides: gateBase(
        crewError: const ApiException(status: 404, title: 'No crew'),
      ),
      child: _gate(),
    );

    expect(find.byType(NoAssignment), findsOneWidget);
    expect(find.text('Sin asignación'), findsOneWidget);
    expect(find.textContaining('asignación para hoy'), findsOneWidget);
    // No se construye el contenido operativo.
    expect(find.textContaining('VEH='), findsNothing);
  });

  testWidgets(
    'SIN cuadrilla pero con ruta EN CURSO recupera la ruta y NO bloquea',
    (tester) async {
      // Red de seguridad: aunque `my-crew` no devuelva asignación (p. ej. una
      // entrega que cruzó la medianoche o lleva días abierta), si hay una ruta
      // ABIERTA del último camión conocido, el chofer sigue operándola.
      await pumpScoped(
        tester,
        overrides: gateBase(
          crewError: const ApiException(status: 404, title: 'No crew'),
          route: buildRoute(vehicleId: 'v-9'),
        ),
        child: _gate(),
      );

      expect(find.text('VEH=v-9'), findsOneWidget);
      expect(find.byType(NoAssignment), findsNothing);
      // Sin cuadrilla no hay cabecera de asignación.
      expect(find.byType(AssignmentHeader), findsNothing);
    },
  );

  testWidgets('SIN cuadrilla y con ruta CERRADA sí bloquea', (tester) async {
    // Una ruta ya completada NO revive el gate: ahí sí es sin asignación.
    await pumpScoped(
      tester,
      overrides: gateBase(
        crewError: const ApiException(status: 404, title: 'No crew'),
        route: buildEmptyRoute(), // completada, sin paradas
      ),
      child: _gate(),
    );

    expect(find.byType(NoAssignment), findsOneWidget);
    expect(find.textContaining('VEH='), findsNothing);
  });

  testWidgets('error de conexión muestra el mensaje de la ApiException', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      overrides: gateBase(
        crewError: const ApiException(
          status: 0,
          title: 'offline',
          isConnectionError: true,
        ),
      ),
      child: _gate(),
    );

    expect(find.byType(NoAssignment), findsOneWidget);
    expect(
      find.text('No se pudo completar. Intentá de nuevo en un momento.'),
      findsOneWidget,
    );
  });
}
