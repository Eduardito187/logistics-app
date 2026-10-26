import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../widgets/route_points.dart';

/// Paradas que el chofer ya resolvió EN ESTE TELÉFONO (POD o entrega fallida
/// registrados) aunque el backend todavía no lo sepa: sin señal el registro
/// queda en la cola offline y la ruta del servidor sigue diciendo "pendiente".
/// Con esto la entrega en curso avanza igual a la siguiente parada y la lista
/// muestra el estado real (offline invisible).
///
/// Clave: id de la parada; valor: cómo se resolvió (completada o fallida).
/// Solo vive en la sesión (memoria), acotado a [maxEntries], y cada parada se
/// quita sola en cuanto el backend la devuelve resuelta ([reconcile]).
class LocallySettledStops extends Notifier<Map<String, DriverRouteStopStatus>> {
  /// Tope de entradas: una ruta urbana tiene decenas de paradas; con el tope se
  /// descartan las más viejas y la memoria queda acotada.
  static const int maxEntries = 100;

  @override
  Map<String, DriverRouteStopStatus> build() => const {};

  /// Marca [stopId] como resuelta localmente ([status] completada o fallida).
  void settle(String stopId, DriverRouteStopStatus status) {
    if (state[stopId] == status) return;
    final next = LinkedHashMap<String, DriverRouteStopStatus>.of(state)
      ..remove(stopId)
      ..[stopId] = status;
    while (next.length > maxEntries) {
      next.remove(next.keys.first);
    }
    state = Map.unmodifiable(next);
  }

  /// Quita las paradas que [route] ya trae resueltas (el backend recibió el
  /// registro): desde ahí manda el estado del servidor. Sin cambios no notifica.
  void reconcile(DriverRoute route) {
    if (state.isEmpty) return;
    final resolved = <String>{
      for (final s in route.stops)
        if (s.status != DriverRouteStopStatus.pending &&
            state.containsKey(s.id))
          s.id,
    };
    final current = route.currentStop;
    if (current != null &&
        current.status != DriverRouteStopStatus.pending &&
        state.containsKey(current.id)) {
      resolved.add(current.id);
    }
    if (resolved.isEmpty) return;
    state = Map.unmodifiable({
      for (final e in state.entries)
        if (!resolved.contains(e.key)) e.key: e.value,
    });
  }
}

final locallySettledStopsProvider =
    NotifierProvider<LocallySettledStops, Map<String, DriverRouteStopStatus>>(
      LocallySettledStops.new,
    );

/// Estado a mostrar de [stop]: el del backend, salvo que siga "pendiente" y el
/// chofer ya la haya resuelto en este teléfono.
DriverRouteStopStatus effectiveStopStatus(
  DriverRouteStop stop,
  Map<String, DriverRouteStopStatus> settled,
) => stop.status == DriverRouteStopStatus.pending
    ? settled[stop.id] ?? stop.status
    : stop.status;

/// Parada en curso: la que marca el backend (si no se resolvió localmente) o,
/// si no la marca, la primera pendiente en orden. `null` cuando ya no quedan
/// paradas por atender.
DriverRouteStop? currentStopOf(
  DriverRoute route, [
  Map<String, DriverRouteStopStatus> settled = const {},
]) {
  final current = route.currentStop;
  if (current != null && !settled.containsKey(current.id)) return current;
  // Ordenadas una vez por ruta (memoizado): sin ordenar en cada build.
  for (final s in sortedStops(route)) {
    if (effectiveStopStatus(s, settled) == DriverRouteStopStatus.pending) {
      return s;
    }
  }
  return null;
}

/// Primera parada PENDIENTE (para el rastreo): la en curso si sigue pendiente,
/// si no la primera pendiente en orden. Respeta lo resuelto localmente.
DriverRouteStop? pendingStopOf(
  DriverRoute route, [
  Map<String, DriverRouteStopStatus> settled = const {},
]) {
  final current = route.currentStop;
  if (current != null &&
      effectiveStopStatus(current, settled) == DriverRouteStopStatus.pending) {
    return current;
  }
  for (final s in sortedStops(route)) {
    if (effectiveStopStatus(s, settled) == DriverRouteStopStatus.pending) {
      return s;
    }
  }
  return null;
}
