import '../../features/driver/domain/entities/route_navigation.dart';
import '../../features/driver/presentation/controllers/locally_settled_stops.dart';
import '../../features/driver/presentation/widgets/active_delivery/delivery_status_card.dart'
    show arrivedAtStop;
import '../api/export.dart';
import 'route_live_state.dart';
import 'route_live_status.dart';

/// Arma la foto de la ruta para la notificación en vivo con las MISMAS reglas
/// que la pantalla "Entrega en curso": parada en curso con [currentStopOf]
/// (respeta lo resuelto en este teléfono, [settled]), geocerca de llegada con
/// [arrivedAtStop] y la ETA del backend.
///
/// `null` cuando no hay nada que mostrar (ruta sin paradas). Con todas las
/// paradas atendidas devuelve el estado [RouteLiveState.finished].
///
/// Puro y barato: se evalúa con cada fix del GPS; el controller decide si
/// publicar (ver `RouteLiveUpdatesController`).
RouteLiveStatus? routeLiveStatusFor({
  required DriverRoute route,
  Map<String, DriverRouteStopStatus> settled = const {},
  RemainingEstimate? remaining,
}) {
  if (route.stops.isEmpty) return null;
  final total = route.stops.length;
  // Atendidas ITEM POR ITEM (estado efectivo = backend + lo resuelto en este
  // teléfono), NUNCA `route.completedStops` del backend (cuenta fallidas y
  // reprogramadas como "completadas" → el avance de la isla mentía).
  var attended = 0;
  for (final s in route.stops) {
    if (effectiveStopStatus(s, settled) != DriverRouteStopStatus.pending) {
      attended++;
    }
  }
  final completed = attended.clamp(0, total);

  // Item por item, como el resto del app: la parada en curso sale de
  // currentStopOf (estado efectivo = backend + lo resuelto en este teléfono),
  // NUNCA de `route.status == completed` del backend (que marca la ruta
  // completada de más → la isla decía "Ruta completada" mientras la pantalla de
  // entrega seguía mostrando una parada pendiente).
  final stop = currentStopOf(route, settled);
  if (stop == null) {
    return RouteLiveStatus(
      routeId: route.id,
      stopId: '',
      stopIndex: total,
      stopCount: total,
      completedCount: total,
      customer: '',
      state: RouteLiveState.finished,
    );
  }

  final name = _firstNonBlank([stop.customerName, stop.address]) ?? 'Cliente';
  final arrived = remaining != null && arrivedAtStop(remaining);
  return RouteLiveStatus(
    routeId: route.id,
    stopId: stop.id,
    stopIndex: stop.sequence,
    stopCount: total,
    completedCount: completed,
    customer: RouteLiveStatus.shortCustomer(name),
    state: arrived ? RouteLiveState.arriving : RouteLiveState.onTheWay,
    etaAt: stop.etaAt,
    remainingMeters: remaining?.meters,
    lat: stop.lat,
    lng: stop.lng,
  );
}

String? _firstNonBlank(List<String?> values) {
  for (final v in values) {
    final t = v?.trim();
    if (t != null && t.isNotEmpty) return t;
  }
  return null;
}
