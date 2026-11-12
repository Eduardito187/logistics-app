import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/live_updates/route_live_state.dart';
import 'package:logistics_app/core/live_updates/route_live_status.dart';
import 'package:logistics_app/core/live_updates/route_live_status_builder.dart';
import 'package:logistics_app/features/driver/domain/entities/route_navigation.dart';

import '../../features/driver/support/driver_test_support.dart';

RemainingEstimate _remaining(double meters, {bool offRoute = false}) =>
    RemainingEstimate(
      meters: meters,
      duration: const Duration(minutes: 5),
      alongRoute: true,
      offRoute: offRoute,
    );

DriverRoute _route({
  DriverRouteStatus status = DriverRouteStatus.inProgress,
  int completed = 1,
}) => buildRoute(
  status: status,
  totalStops: 3,
  completedStops: completed,
  stops: [
    buildStop(
      id: 's1',
      sequence: 1,
      status: DriverRouteStopStatus.completed,
      customerName: 'Ana',
    ),
    buildStop(
      id: 's2',
      sequence: 2,
      customerName: '  Ferretería El Constructor de Santa Cruz SRL  ',
      etaAt: DateTime(2026, 11, 11, 9, 5),
      lat: -17.7,
      lng: -63.1,
    ),
    buildStop(id: 's3', sequence: 3, customerName: null, address: 'Av. Busch'),
  ],
);

void main() {
  test('sin paradas no hay nada que mostrar', () {
    expect(routeLiveStatusFor(route: buildEmptyRoute()), isNull);
  });

  test('parada en curso: N de M, ETA, avance, cliente acortado', () {
    final status = routeLiveStatusFor(
      route: _route(),
      remaining: _remaining(2300),
    )!;
    expect(status.stopId, 's2');
    expect(status.stopIndex, 2);
    expect(status.stopCount, 3);
    expect(status.completedCount, 1);
    expect(status.progress, closeTo(1 / 3, 1e-9));
    expect(status.state, RouteLiveState.onTheWay);
    expect(status.customer.length, RouteLiveStatus.maxCustomerLength);
    expect(status.customer.endsWith('…'), isTrue);
    expect(status.title, 'Parada 2 de 3 · Llega 09:05');
    expect(status.subText, 'A 2,3 km');
    expect(status.chipText, '2/3 · 09:05');
    expect(status.lat, -17.7);
  });

  test('dentro de la geocerca (≤ 60 m) → "Llegaste"', () {
    final status = routeLiveStatusFor(
      route: _route(),
      remaining: _remaining(40),
    )!;
    expect(status.state, RouteLiveState.arriving);
    expect(status.title, 'Llegaste · Parada 2 de 3');
    expect(status.chipText, '2/3 · Llegó');
    expect(status.subText, isNull);
  });

  test('fuera de ruta no cuenta como llegada', () {
    final status = routeLiveStatusFor(
      route: _route(),
      remaining: _remaining(40, offRoute: true),
    )!;
    expect(status.state, RouteLiveState.onTheWay);
  });

  test('lo resuelto en este teléfono avanza la parada y el avance', () {
    final status = routeLiveStatusFor(
      route: _route(),
      settled: const {'s2': DriverRouteStopStatus.completed},
    )!;
    expect(status.stopId, 's3');
    expect(status.completedCount, 2);
    // Sin nombre de cliente cae a la dirección.
    expect(status.customer, 'Av. Busch');
    // Sin ETA el chip muestra el avance.
    expect(status.chipText, '3/3');
    expect(status.title, 'Parada 3 de 3');
  });

  test('todas atendidas → finalizada', () {
    final status = routeLiveStatusFor(
      route: _route(),
      settled: const {
        's2': DriverRouteStopStatus.completed,
        's3': DriverRouteStopStatus.failed,
      },
    )!;
    expect(status.state, RouteLiveState.finished);
    expect(status.title, 'Ruta completada');
    expect(status.body, 'Atendiste las 3 paradas del día.');
    expect(status.progress, 1);
  });

  test('ruta completada en el backend → finalizada', () {
    final status = routeLiveStatusFor(
      route: _route(status: DriverRouteStatus.completed, completed: 3),
    )!;
    expect(status.state, RouteLiveState.finished);
  });

  test('sameContentAs ignora metros que no cambian el texto', () {
    final a = routeLiveStatusFor(route: _route(), remaining: _remaining(2310))!;
    final b = routeLiveStatusFor(route: _route(), remaining: _remaining(2340))!;
    final c = routeLiveStatusFor(route: _route(), remaining: _remaining(1800))!;
    expect(a.sameContentAs(b), isTrue);
    expect(a.sameContentAs(c), isFalse);
    expect(a.majorChangeFrom(c), isFalse);
  });
}
