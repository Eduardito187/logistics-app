import 'dart:math' as math;

import '../../features/driver/presentation/controllers/locally_settled_stops.dart';
import '../../features/supervisor/domain/dashboard_metrics.dart';
import '../api/export.dart';
import '../auth/user_role.dart';
import '../live_updates/route_live_state.dart';
import '../live_updates/route_live_status_builder.dart';
import 'home_widget_kind.dart';
import 'home_widget_payload.dart';
import 'home_widget_sources.dart';
import 'home_widget_state.dart';
import 'next_delivery_payload.dart';
import 'picking_pending_payload.dart';
import 'quick_scan_payload.dart';
import 'role_home_widgets.dart';
import 'route_day_payload.dart';
import 'store_receptions_payload.dart';
import 'supervisor_summary_payload.dart';

// Builders PUROS de los payloads de los widgets: sin Flutter, sin providers,
// sin red. Reciben los datos que el inicio ya cargó y devuelven lo que se
// pinta. Probados en `test/core/home_widgets/home_widget_builders_test.dart`.

/// Texto de cliente con "Ocultar nombre del cliente en widgets".
const String kHiddenCustomer = 'Cliente';

/// Payloads del rol [role] con lo que hay en [sources]. Un widget cuyos datos
/// todavía no se cargaron NO aparece (queda lo último publicado).
///
/// [now] decide qué ruta del chofer es la de HOY (si mira otro día en "Mi
/// ruta", los widgets no cambian).
List<HomeWidgetPayload> homeWidgetPayloadsFor({
  required UserRole role,
  required HomeWidgetSources sources,
  required DateTime now,
  bool hideCustomer = false,
}) {
  final today = _todayRoute(sources, now);
  final orders = sources.pickingOrders;
  final shipments = sources.storeShipments;
  final result = <HomeWidgetPayload>[];
  for (final kind in homeWidgetKindsFor(role)) {
    final HomeWidgetPayload? payload = switch (kind) {
      HomeWidgetKind.nextDelivery =>
        today == null
            ? null
            : nextDeliveryPayloadFor(
                route: today,
                settled: sources.settledStops,
                hideCustomer: hideCustomer,
              ),
      HomeWidgetKind.routeDay =>
        today == null
            ? null
            : routeDayPayloadFor(route: today, settled: sources.settledStops),
      HomeWidgetKind.pickingPending =>
        orders == null ? null : pickingPendingPayloadFor(orders),
      HomeWidgetKind.storeReceptions =>
        shipments == null ? null : storeReceptionsPayloadFor(shipments),
      HomeWidgetKind.supervisorSummary => supervisorSummaryPayloadFor(
        metrics: sources.dashboardMetrics,
        fleet: sources.fleet,
      ),
      HomeWidgetKind.quickScan => quickScanPayloadFor(role),
    };
    if (payload != null) result.add(payload);
  }
  return result;
}

/// "Próxima entrega" con las MISMAS reglas que la notificación de ruta en vivo
/// y la pantalla "Entrega en curso" ([routeLiveStatusFor]): parada en curso
/// respetando lo resuelto en este teléfono ([settled]) y la ETA del backend.
/// Sin paradas o con la ruta terminada → [HomeWidgetState.empty].
NextDeliveryPayload nextDeliveryPayloadFor({
  required DriverRoute route,
  Map<String, DriverRouteStopStatus> settled = const {},
  bool hideCustomer = false,
}) {
  final status = routeLiveStatusFor(route: route, settled: settled);
  if (status == null || status.state == RouteLiveState.finished) {
    return NextDeliveryPayload(
      state: HomeWidgetState.empty,
      route: kNextDeliveryRoute,
      stopIndex: status?.stopIndex ?? 0,
      stopCount: status?.stopCount ?? 0,
      customer: '',
      progress: status?.progress ?? 0,
    );
  }
  final address = currentStopOf(route, settled)?.address?.trim();
  return NextDeliveryPayload(
    state: HomeWidgetState.ok,
    route: kNextDeliveryRoute,
    stopIndex: status.stopIndex,
    stopCount: status.stopCount,
    customer: hideCustomer ? kHiddenCustomer : status.customer,
    etaText: status.etaText,
    progress: status.progress,
    address: hideCustomer || address == null || address.isEmpty
        ? null
        : address,
    lat: status.lat,
    lng: status.lng,
  );
}

/// "Mi ruta de hoy": entregadas, fallidas y pendientes, contando las paradas
/// resueltas en este teléfono ([settled]) como la entrega en curso.
RouteDayPayload routeDayPayloadFor({
  required DriverRoute route,
  Map<String, DriverRouteStopStatus> settled = const {},
}) {
  final total = route.totalStops > 0 ? route.totalStops : route.stops.length;
  var delivered = 0;
  var failed = 0;
  for (final stop in route.stops) {
    switch (effectiveStopStatus(stop, settled)) {
      case DriverRouteStopStatus.completed:
        delivered++;
      case DriverRouteStopStatus.failed:
        failed++;
      case DriverRouteStopStatus.pending:
      case DriverRouteStopStatus.$unknown:
        break;
    }
  }
  return RouteDayPayload(
    state: total == 0 ? HomeWidgetState.empty : HomeWidgetState.ok,
    route: kRouteDayRoute,
    delivered: delivered,
    pending: math.max(0, total - delivered - failed),
    failed: failed,
    total: total,
  );
}

/// "Pedidos por preparar" desde la worklist del preparador: recibidos = por
/// preparar; planificados = en preparación/carga (mismos estados que
/// `ListOrdersToPrepare`).
PickingPendingPayload pickingPendingPayloadFor(List<Shipment> orders) {
  var pending = 0;
  var inProgress = 0;
  for (final order in orders) {
    switch (order.status) {
      case ShipmentStatus.received:
        pending++;
      case ShipmentStatus.planned:
        inProgress++;
      case ShipmentStatus.inExecution:
      case ShipmentStatus.delivered:
      case ShipmentStatus.failed:
      case ShipmentStatus.cancelled:
      case ShipmentStatus.$unknown:
        break;
    }
  }
  return PickingPendingPayload(
    state: pending + inProgress == 0
        ? HomeWidgetState.empty
        : HomeWidgetState.ok,
    route: kPickingPendingRoute,
    pending: pending,
    inProgress: inProgress,
    scanRoute: kPickingScanRoute,
  );
}

/// "Recepción en tienda" desde los envíos de la tienda del usuario:
/// planificados o en ejecución = vienen en camino; recibidos = para recojo.
StoreReceptionsPayload storeReceptionsPayloadFor(List<Shipment> shipments) {
  var incoming = 0;
  var pickups = 0;
  for (final shipment in shipments) {
    switch (shipment.status) {
      case ShipmentStatus.planned:
      case ShipmentStatus.inExecution:
        incoming++;
      case ShipmentStatus.received:
        pickups++;
      case ShipmentStatus.delivered:
      case ShipmentStatus.failed:
      case ShipmentStatus.cancelled:
      case ShipmentStatus.$unknown:
        break;
    }
  }
  return StoreReceptionsPayload(
    state: incoming + pickups == 0 ? HomeWidgetState.empty : HomeWidgetState.ok,
    route: kStoreReceptionsRoute,
    incoming: incoming,
    pickups: pickups,
  );
}

/// "Resumen del día" del supervisor: entregas y alertas abiertas del tablero
/// de HOY ([metrics]); camiones en ruta de la flota en vivo ([fleet]: con
/// ruta asignada) o, si la flota no se abrió, las rutas publicadas del
/// tablero. `null` si no hay ninguno de los dos.
SupervisorSummaryPayload? supervisorSummaryPayloadFor({
  DashboardMetrics? metrics,
  List<VehicleLive>? fleet,
}) {
  if (metrics == null && fleet == null) return null;
  final trucks = fleet != null
      ? fleet.where((v) => v.routeId != null).length
      : metrics?.activePlans ?? 0;
  return SupervisorSummaryPayload(
    state: HomeWidgetState.ok,
    route: kSupervisorSummaryRoute,
    delivered: metrics?.delivered ?? 0,
    incidents: metrics?.openAlerts ?? 0,
    trucksOnRoute: trucks,
  );
}

/// "Escanear" del rol, o `null` si el rol no tiene tarea de escaneo.
QuickScanPayload? quickScanPayloadFor(UserRole role) {
  final route = kQuickScanRoutes[role];
  if (route == null) return null;
  return QuickScanPayload(state: HomeWidgetState.ok, route: route);
}

/// "Escanear" sin sesión: invita a iniciar sesión.
const QuickScanPayload kSignedOutQuickScan = QuickScanPayload(
  state: HomeWidgetState.signedOut,
  route: kHomeWidgetSignedOutRoute,
);

/// ¿[date] es el mismo día calendario que [now]? Compara año/mes/día tal cual
/// (la fecha de la ruta viene sin hora: no se convierte de zona).
bool isSameRouteDay(DateTime date, DateTime now) =>
    date.year == now.year && date.month == now.month && date.day == now.day;

DriverRoute? _todayRoute(HomeWidgetSources sources, DateTime now) {
  final route = sources.driverRoute;
  if (route == null || !isSameRouteDay(route.routeDate, now)) return null;
  return route;
}
