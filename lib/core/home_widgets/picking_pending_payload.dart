import 'home_widget_kind.dart';
import 'home_widget_payload.dart';
import 'home_widget_state.dart';

/// "Pedidos por preparar" (preparador / andén).
class PickingPendingPayload extends HomeWidgetPayload {
  const PickingPendingPayload({
    required this.state,
    required this.route,
    required this.pending,
    required this.inProgress,
    required this.scanRoute,
  });

  @override
  HomeWidgetKind get kind => HomeWidgetKind.pickingPending;

  @override
  final HomeWidgetState state;

  @override
  final String route;

  /// Pedidos recibidos, todavía por preparar.
  final int pending;

  /// Pedidos ya planificados en una ruta (en preparación / carga).
  final int inProgress;

  /// Ruta del botón "Escanear" del widget (ingresar pedido).
  final String scanRoute;

  @override
  Map<String, Object?> get fields => {
    'pending': pending,
    'inProgress': inProgress,
    'scanRoute': scanRoute,
  };
}
