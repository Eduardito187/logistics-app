import 'package:flutter/foundation.dart';

import '../../features/supervisor/domain/dashboard_metrics.dart';
import '../api/export.dart';

/// Últimos datos que los providers del inicio YA cargaron y que los widgets
/// reflejan. Nunca se piden datos para los widgets: si un provider no está
/// vivo, queda su último valor (o nada).
@immutable
class HomeWidgetSources {
  const HomeWidgetSources({
    this.driverRoute,
    this.settledStops = const {},
    this.pickingOrders,
    this.storeShipments,
    this.dashboardMetrics,
    this.fleet,
  });

  /// Ruta del chofer (la de HOY se filtra al armar los payloads).
  final DriverRoute? driverRoute;

  /// Paradas resueltas en este teléfono (`locallySettledStopsProvider`).
  final Map<String, DriverRouteStopStatus> settledStops;

  /// Pedidos por preparar (`ordersToPrepareProvider`).
  final List<Shipment>? pickingOrders;

  /// Envíos de la tienda del usuario (`storeShipmentsProvider`).
  final List<Shipment>? storeShipments;

  /// Tablero del día del supervisor (`dashboardMetricsProvider`, solo hoy).
  final DashboardMetrics? dashboardMetrics;

  /// Flota en vivo (`fleetLiveProvider`).
  final List<VehicleLive>? fleet;

  /// Sin `null` para "borrar": los datos solo se reemplazan; el cierre de
  /// sesión vuelve a `const HomeWidgetSources()`.
  HomeWidgetSources copyWith({
    DriverRoute? driverRoute,
    Map<String, DriverRouteStopStatus>? settledStops,
    List<Shipment>? pickingOrders,
    List<Shipment>? storeShipments,
    DashboardMetrics? dashboardMetrics,
    List<VehicleLive>? fleet,
  }) => HomeWidgetSources(
    driverRoute: driverRoute ?? this.driverRoute,
    settledStops: settledStops ?? this.settledStops,
    pickingOrders: pickingOrders ?? this.pickingOrders,
    storeShipments: storeShipments ?? this.storeShipments,
    dashboardMetrics: dashboardMetrics ?? this.dashboardMetrics,
    fleet: fleet ?? this.fleet,
  );
}
