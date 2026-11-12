import 'home_widget_kind.dart';
import 'home_widget_payload.dart';
import 'home_widget_state.dart';

/// "Resumen del día" (supervisor): tablero del día + flota en vivo.
class SupervisorSummaryPayload extends HomeWidgetPayload {
  const SupervisorSummaryPayload({
    required this.state,
    required this.route,
    required this.delivered,
    required this.incidents,
    required this.trucksOnRoute,
  });

  @override
  HomeWidgetKind get kind => HomeWidgetKind.supervisorSummary;

  @override
  final HomeWidgetState state;

  @override
  final String route;

  /// Entregas completadas hoy.
  final int delivered;

  /// Alertas sin reconocer.
  final int incidents;

  /// Camiones en ruta.
  final int trucksOnRoute;

  @override
  Map<String, Object?> get fields => {
    'delivered': delivered,
    'incidents': incidents,
    'trucksOnRoute': trucksOnRoute,
  };
}
