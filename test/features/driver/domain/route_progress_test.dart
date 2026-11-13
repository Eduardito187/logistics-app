import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/driver/domain/route_progress.dart';

import '../support/driver_test_support.dart';

// RouteProgress: fuente ÚNICA de avance de la ruta, calculada ITEM POR ITEM con
// el estado efectivo de cada parada (nunca con los conteos agregados del
// backend). Debe coincidir con la lista, el resumen y "Mi día".

void main() {
  group('RouteProgress.of', () {
    test('cuenta por estado efectivo de cada parada', () {
      final route = buildRoute(
        // Agregados del backend A PROPÓSITO distintos de las paradas: no deben
        // usarse cuando hay lista de paradas.
        totalStops: 99,
        completedStops: 99,
        stopsRemaining: 0,
        stops: [
          buildStop(id: 'a', status: DriverRouteStopStatus.completed),
          buildStop(id: 'b', status: DriverRouteStopStatus.completed),
          buildStop(id: 'c', status: DriverRouteStopStatus.failed),
          buildStop(id: 'd'),
        ],
      );
      final p = RouteProgress.of(route);
      expect(p.total, 4);
      expect(p.delivered, 2);
      expect(p.failed, 1);
      expect(p.pending, 1);
      expect(p.attended, 3);
      expect(p.isComplete, isFalse); // queda 1 pendiente
    });

    test('lo resuelto en este teléfono (offline) avanza el conteo', () {
      final route = buildRoute(
        stops: [
          buildStop(id: 'a', status: DriverRouteStopStatus.completed),
          buildStop(id: 'b'),
        ],
      );
      final p = RouteProgress.of(route, const {
        'b': DriverRouteStopStatus.completed,
      });
      expect(p.delivered, 2);
      expect(p.pending, 0);
      expect(p.isComplete, isTrue);
    });

    test('ruta terminada con una fallida: completa pero no todas entregadas', () {
      // El bug del dueño: "6 de 7 y ya completada". Acá: sin pendientes la ruta
      // ESTÁ completa, pero delivered < total porque hubo una fallida (el
      // resumen muestra "Completada" y 1 "no entregada", sin inflar entregadas).
      final route = buildRoute(
        stops: [
          for (var i = 0; i < 6; i++)
            buildStop(id: 's$i', status: DriverRouteStopStatus.completed),
          buildStop(id: 's6', status: DriverRouteStopStatus.failed),
        ],
      );
      final p = RouteProgress.of(route);
      expect(p.total, 7);
      expect(p.delivered, 6);
      expect(p.failed, 1);
      expect(p.pending, 0);
      expect(p.isComplete, isTrue);
    });

    test('con una parada pendiente NO está completa aunque el backend lo diga', () {
      final route = buildRoute(
        status: DriverRouteStatus.completed, // backend dice completada
        totalStops: 2,
        completedStops: 2,
        stopsRemaining: 0,
        stops: [
          buildStop(id: 'a', status: DriverRouteStopStatus.completed),
          buildStop(id: 'b'), // pero esta sigue pendiente
        ],
      );
      final p = RouteProgress.of(route);
      expect(p.pending, 1);
      expect(p.isComplete, isFalse);
    });

    test('sin paradas listadas cae a los agregados del backend', () {
      final route = buildRoute(
        totalStops: 5,
        completedStops: 2,
        stopsRemaining: 3,
        stops: const [],
      );
      final p = RouteProgress.of(route);
      expect(p.total, 5);
      expect(p.delivered, 2);
      expect(p.pending, 3);
      expect(p.failed, 0);
      expect(p.isComplete, isFalse);
    });

    test('ruta vacía no está completa (total 0)', () {
      expect(RouteProgress.of(buildEmptyRoute()).isComplete, isFalse);
    });

    test('fraction es las atendidas sobre el total', () {
      final route = buildRoute(
        stops: [
          buildStop(id: 'a', status: DriverRouteStopStatus.completed),
          buildStop(id: 'b', status: DriverRouteStopStatus.failed),
          buildStop(id: 'c'),
          buildStop(id: 'd'),
        ],
      );
      expect(RouteProgress.of(route).fraction, closeTo(0.5, 1e-9));
    });
  });
}
