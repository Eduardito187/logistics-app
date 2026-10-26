import '../../../../core/api/export.dart';

/// Métricas del día del chofer calculadas en la app a partir de la ruta del
/// día (`DriverRoute`). Las KPIs "oficiales" del backend se piden aparte.
class MyDayStats {
  const MyDayStats({
    required this.total,
    required this.delivered,
    required this.failed,
    required this.pending,
    this.firstSettledAt,
    this.lastSettledAt,
    this.averagePerStop,
  });

  /// Arma las métricas desde la ruta. El total sale de las paradas listadas
  /// (o de `totalStops` si la lista viene vacía).
  factory MyDayStats.fromRoute(DriverRoute route) {
    final stops = route.stops;
    final total = stops.isEmpty ? route.totalStops : stops.length;
    final delivered = stops
        .where((s) => s.status == DriverRouteStopStatus.completed)
        .length;
    final failed = stops
        .where((s) => s.status == DriverRouteStopStatus.failed)
        .length;
    final pending = (total - delivered - failed).clamp(0, total);

    final settled =
        stops
            .map((s) => s.settledAt)
            .whereType<DateTime>()
            .toList(growable: false)
          ..sort();
    final first = settled.isEmpty ? null : settled.first;
    final last = settled.isEmpty ? null : settled.last;
    // Promedio entre cierres consecutivos: con N paradas cerradas hay N-1
    // intervalos. Con una sola no hay referencia de cuánto tomó.
    final average = settled.length < 2
        ? null
        : Duration(
            seconds: last!.difference(first!).inSeconds ~/ (settled.length - 1),
          );

    return MyDayStats(
      total: total,
      delivered: delivered,
      failed: failed,
      pending: pending,
      firstSettledAt: first,
      lastSettledAt: last,
      averagePerStop: average,
    );
  }

  final int total;
  final int delivered;
  final int failed;
  final int pending;

  /// Hora del primer cierre (entregada o fallida) del día.
  final DateTime? firstSettledAt;

  /// Hora del último cierre del día.
  final DateTime? lastSettledAt;

  /// Tiempo promedio por parada (entre cierres consecutivos).
  final Duration? averagePerStop;

  /// Paradas atendidas (entregadas + fallidas).
  int get attended => delivered + failed;

  /// Avance del día en [0, 1].
  double get progress => total == 0 ? 0 : attended / total;
}
