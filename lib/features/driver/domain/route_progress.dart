import '../../../core/api/export.dart';
import 'effective_stop_status.dart';

/// Avance de la ruta calculado ITEM POR ITEM con el estado EFECTIVO de cada
/// parada ([effectiveStopStatus] = backend + lo resuelto en este teléfono),
/// NUNCA con los conteos agregados del backend (`completed_stops`,
/// `stops_remaining`, `status`).
///
/// Por qué: los agregados del backend pueden quedar atrás respecto de las
/// paradas (una entrega registrada que el backend todavía no reflejó en el
/// conteo, o un conteo que avanza sin que las paradas cambien). Cuando el anillo
/// de avance usaba `completed_stops` y la lista usaba el estado por parada, se
/// contradecían: "5/7" en el resumen pero 6 paradas marcadas entregadas en la
/// lista, o "ruta completada" con una parada aún pendiente. Esta es la FUENTE
/// ÚNICA de avance para el resumen, la barra de progreso, la detección de ruta
/// terminada y las métricas de "Mi día".
class RouteProgress {
  const RouteProgress({
    required this.total,
    required this.delivered,
    required this.failed,
    required this.pending,
  });

  /// Cuenta las paradas por su estado efectivo. Si la ruta todavía NO trae
  /// paradas listadas (sólo pasa antes de tener la hoja de ruta armada), se cae
  /// a los agregados del backend como último recurso.
  factory RouteProgress.of(
    DriverRoute route, [
    Map<String, DriverRouteStopStatus> settled = const {},
  ]) {
    final stops = route.stops;
    if (stops.isEmpty) {
      final total = route.totalStops;
      final delivered = route.completedStops.clamp(0, total);
      return RouteProgress(
        total: total,
        delivered: delivered,
        failed: 0,
        pending: (total - delivered).clamp(0, total),
      );
    }
    var delivered = 0;
    var failed = 0;
    for (final stop in stops) {
      switch (effectiveStopStatus(stop, settled)) {
        case DriverRouteStopStatus.completed:
          delivered++;
        case DriverRouteStopStatus.failed:
          failed++;
        default:
          break;
      }
    }
    final total = stops.length;
    return RouteProgress(
      total: total,
      delivered: delivered,
      failed: failed,
      pending: (total - delivered - failed).clamp(0, total),
    );
  }

  /// Paradas de la ruta (listadas, o el total del backend si aún no hay lista).
  final int total;

  /// Paradas entregadas (estado efectivo = completada).
  final int delivered;

  /// Paradas con entrega fallida (estado efectivo = fallida).
  final int failed;

  /// Paradas que aún faltan atender.
  final int pending;

  /// Paradas ya atendidas (entregadas + fallidas).
  int get attended => delivered + failed;

  /// La ruta está terminada cuando hay paradas y NINGUNA sigue pendiente. Nunca
  /// por el `status`/conteo del backend (podían decir "completada" de más).
  bool get isComplete => total > 0 && pending == 0;

  /// Fracción atendida en [0, 1] (para anillos y barras de progreso).
  double get fraction =>
      total == 0 ? 0 : (attended / total).clamp(0.0, 1.0).toDouble();
}
