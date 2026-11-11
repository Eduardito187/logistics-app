import 'home_widget_kind.dart';
import 'home_widget_payload.dart';
import 'home_widget_state.dart';

/// "Recepción en tienda" (tienda): envíos de SU tienda.
class StoreReceptionsPayload extends HomeWidgetPayload {
  const StoreReceptionsPayload({
    required this.state,
    required this.route,
    required this.incoming,
    required this.pickups,
  });

  @override
  HomeWidgetKind get kind => HomeWidgetKind.storeReceptions;

  @override
  final HomeWidgetState state;

  @override
  final String route;

  /// Envíos en camino a la tienda (planificados o en ejecución).
  final int incoming;

  /// Envíos para recojo en tienda (recibidos).
  final int pickups;

  @override
  Map<String, Object?> get fields => {'incoming': incoming, 'pickups': pickups};
}
