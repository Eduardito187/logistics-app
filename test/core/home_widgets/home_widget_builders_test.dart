import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/home_widgets/home_widget_builders.dart';
import 'package:logistics_app/core/home_widgets/home_widget_kind.dart';
import 'package:logistics_app/core/home_widgets/home_widget_sources.dart';
import 'package:logistics_app/features/supervisor/domain/dashboard_metrics.dart';

import '../../features/driver/support/driver_test_support.dart';
import '../../features/supervisor/support/supervisor_fixtures.dart';

// Builders puros de los widgets de la pantalla de inicio: payload EXACTO por
// rol (lo que recibe el nativo), privacidad del cliente y ruta de HOY.

final _updatedAt = DateTime.fromMillisecondsSinceEpoch(1000);
final _today = DateTime(2026, 10, 15, 9); // = routeDate de buildRoute

DriverRoute _route() => buildRoute(
  totalStops: 3,
  completedStops: 1,
  stops: [
    buildStop(
      id: 's1',
      sequence: 1,
      customerName: 'Ana',
      status: DriverRouteStopStatus.completed,
    ),
    buildStop(
      id: 's2',
      sequence: 2,
      customerName: 'Beto Rojas',
      address: ' Av. Banzer 123 ',
      etaAt: DateTime(2026, 10, 15, 8, 15),
      lat: -17.78,
      lng: -63.18,
    ),
    buildStop(id: 's3', sequence: 3, customerName: 'Carla'),
  ],
);

VehicleLive _truck(String id, {String? routeId}) => VehicleLive(
  vehicleId: id,
  lat: 0,
  lng: 0,
  moving: true,
  recordedAt: DateTime(2026, 10, 15),
  routeId: routeId,
);

void main() {
  group('chofer', () {
    test('next_delivery: parada en curso, ETA local y progreso', () {
      final p = nextDeliveryPayloadFor(route: _route());
      expect(p.kind, HomeWidgetKind.nextDelivery);
      expect(p.toMap(updatedAt: _updatedAt), {
        'state': 'ok',
        'updatedAt': 1000,
        'route': '/driver/delivery',
        'stopIndex': 2,
        'stopCount': 3,
        'customer': 'Beto Rojas',
        'etaText': '08:15',
        'progress': 1 / 3,
        'address': 'Av. Banzer 123',
        'lat': -17.78,
        'lng': -63.18,
      });
    });

    test('privacidad: "Cliente" y sin dirección', () {
      final map = nextDeliveryPayloadFor(
        route: _route(),
        hideCustomer: true,
      ).toMap(updatedAt: _updatedAt);
      expect(map['customer'], 'Cliente');
      expect(map['address'], isNull);
      expect(map['stopIndex'], 2);
    });

    test('parada resuelta en este teléfono avanza a la siguiente', () {
      final p = nextDeliveryPayloadFor(
        route: _route(),
        settled: {'s2': DriverRouteStopStatus.failed},
      );
      expect(p.stopIndex, 3);
      expect(p.customer, 'Carla');
      expect(p.progress, 2 / 3);
    });

    test('ruta terminada → empty con progreso completo', () {
      final p = nextDeliveryPayloadFor(
        route: _route(),
        settled: {
          's2': DriverRouteStopStatus.completed,
          's3': DriverRouteStopStatus.completed,
        },
      );
      expect(p.toMap(updatedAt: _updatedAt), {
        'state': 'empty',
        'updatedAt': 1000,
        'route': '/driver/delivery',
        'stopIndex': 3,
        'stopCount': 3,
        'customer': '',
        'etaText': null,
        'progress': 1.0,
        'address': null,
        'lat': null,
        'lng': null,
      });
    });

    test('route_day cuenta lo resuelto localmente', () {
      final p = routeDayPayloadFor(
        route: _route(),
        settled: {'s2': DriverRouteStopStatus.failed},
      );
      expect(p.toMap(updatedAt: _updatedAt), {
        'state': 'ok',
        'updatedAt': 1000,
        'route': '/driver/route',
        'delivered': 1,
        'pending': 1,
        'failed': 1,
        'total': 3,
      });
    });

    test('ruta sin paradas → route_day empty', () {
      final p = routeDayPayloadFor(
        route: buildRoute(totalStops: 0, completedStops: 0),
      );
      expect(p.toMap(updatedAt: _updatedAt)['state'], 'empty');
    });

    test('payloads del rol: solo con la ruta de HOY', () {
      final sources = HomeWidgetSources(driverRoute: _route());
      final today = homeWidgetPayloadsFor(
        role: UserRole.driver,
        sources: sources,
        now: _today,
      );
      expect(today.map((p) => p.kind), [
        HomeWidgetKind.nextDelivery,
        HomeWidgetKind.routeDay,
        HomeWidgetKind.quickScan,
      ]);
      final otherDay = homeWidgetPayloadsFor(
        role: UserRole.driver,
        sources: sources,
        now: DateTime(2026, 10, 16, 9),
      );
      expect(otherDay.map((p) => p.kind), [HomeWidgetKind.quickScan]);
    });

    test('quick_scan del chofer abre la carga del camión', () {
      final scan = quickScanPayloadFor(UserRole.driver)!;
      expect(scan.toMap(updatedAt: _updatedAt), {
        'state': 'ok',
        'updatedAt': 1000,
        'route': '/driver/load',
        'label': 'Escanear',
      });
    });
  });

  test('preparador: recibidos = por preparar, planificados = en curso', () {
    final p = pickingPendingPayloadFor([
      shipment(ShipmentStatus.received, id: 'a'),
      shipment(ShipmentStatus.received, id: 'b'),
      shipment(ShipmentStatus.planned, id: 'c'),
      shipment(ShipmentStatus.delivered, id: 'd'),
    ]);
    expect(p.toMap(updatedAt: _updatedAt), {
      'state': 'ok',
      'updatedAt': 1000,
      'route': '/picking/orders',
      'pending': 2,
      'inProgress': 1,
      'scanRoute': '/picking/prepare',
    });
    expect(
      pickingPendingPayloadFor(const []).toMap(updatedAt: _updatedAt)['state'],
      'empty',
    );
  });

  test('tienda: en camino y para recojo', () {
    final p = storeReceptionsPayloadFor([
      shipment(ShipmentStatus.planned, id: 'a'),
      shipment(ShipmentStatus.inExecution, id: 'b'),
      shipment(ShipmentStatus.received, id: 'c'),
      shipment(ShipmentStatus.cancelled, id: 'd'),
    ]);
    expect(p.toMap(updatedAt: _updatedAt), {
      'state': 'ok',
      'updatedAt': 1000,
      'route': '/store/reception',
      'incoming': 2,
      'pickups': 1,
    });
  });

  group('supervisor', () {
    const metrics = DashboardMetrics(
      received: 0,
      planned: 0,
      inExecution: 3,
      delivered: 7,
      failed: 1,
      cancelled: 0,
      activePlans: 4,
      openAlerts: 2,
    );

    test('tablero + flota: camiones con ruta', () {
      final p = supervisorSummaryPayloadFor(
        metrics: metrics,
        fleet: [_truck('v1', routeId: 'r1'), _truck('v2')],
      );
      expect(p!.toMap(updatedAt: _updatedAt), {
        'state': 'ok',
        'updatedAt': 1000,
        'route': '/supervisor/dashboard',
        'delivered': 7,
        'incidents': 2,
        'trucksOnRoute': 1,
      });
    });

    test('sin flota: rutas publicadas del tablero', () {
      final p = supervisorSummaryPayloadFor(metrics: metrics);
      expect(p!.trucksOnRoute, 4);
    });

    test('sin datos: no hay payload; sin "Escanear" para el supervisor', () {
      expect(supervisorSummaryPayloadFor(), isNull);
      expect(quickScanPayloadFor(UserRole.supervisor), isNull);
      expect(
        homeWidgetPayloadsFor(
          role: UserRole.supervisor,
          sources: const HomeWidgetSources(),
          now: _today,
        ),
        isEmpty,
      );
    });
  });

  test('sin sesión: "Escanear" invita a iniciar sesión', () {
    expect(kSignedOutQuickScan.toMap(updatedAt: _updatedAt), {
      'state': 'signedOut',
      'updatedAt': 1000,
      'route': '/login',
      'label': 'Escanear',
    });
  });
}
