import 'home_widget_kind.dart';
import 'home_widget_payload.dart';
import 'home_widget_state.dart';

/// "Mi ruta de hoy" (chofer): conteo de paradas del día, contando las
/// resueltas en este teléfono que el backend todavía no sabe.
class RouteDayPayload extends HomeWidgetPayload {
  const RouteDayPayload({
    required this.state,
    required this.route,
    required this.delivered,
    required this.pending,
    required this.failed,
    required this.total,
  });

  @override
  HomeWidgetKind get kind => HomeWidgetKind.routeDay;

  @override
  final HomeWidgetState state;

  @override
  final String route;

  final int delivered;
  final int pending;
  final int failed;
  final int total;

  @override
  Map<String, Object?> get fields => {
    'delivered': delivered,
    'pending': pending,
    'failed': failed,
    'total': total,
  };

  /// Cada cambio de conteo es una parada resuelta: se publica al instante.
  @override
  bool isMajorChangeFrom(HomeWidgetPayload previous) {
    if (super.isMajorChangeFrom(previous)) return true;
    final other = previous as RouteDayPayload;
    return other.delivered != delivered ||
        other.pending != pending ||
        other.failed != failed ||
        other.total != total;
  }
}
