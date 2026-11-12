import 'home_widget_kind.dart';
import 'home_widget_payload.dart';
import 'home_widget_state.dart';

/// "Próxima entrega" (chofer): la parada en curso de la ruta de hoy.
class NextDeliveryPayload extends HomeWidgetPayload {
  const NextDeliveryPayload({
    required this.state,
    required this.route,
    required this.stopIndex,
    required this.stopCount,
    required this.customer,
    required this.progress,
    this.etaText,
    this.address,
    this.lat,
    this.lng,
  });

  @override
  HomeWidgetKind get kind => HomeWidgetKind.nextDelivery;

  @override
  final HomeWidgetState state;

  @override
  final String route;

  /// Número de la parada en curso (1-based); con la ruta terminada, el total.
  final int stopIndex;

  /// Total de paradas de la ruta.
  final int stopCount;

  /// Cliente o destino ya acortado ("Cliente" con la privacidad activa; vacío
  /// sin parada en curso).
  final String customer;

  /// Hora estimada de llegada en hora local ("08:15"), o `null` sin ETA.
  final String? etaText;

  /// Avance de la ruta, de 0 a 1.
  final double progress;

  /// Dirección de la parada (`null` sin dato o con la privacidad activa).
  final String? address;

  final double? lat;
  final double? lng;

  @override
  Map<String, Object?> get fields => {
    'stopIndex': stopIndex,
    'stopCount': stopCount,
    'customer': customer,
    'etaText': etaText,
    'progress': progress,
    'address': address,
    'lat': lat,
    'lng': lng,
  };

  /// Otra parada, otro cliente u otra dirección (incluye activar/desactivar la
  /// privacidad) se publica al instante.
  @override
  bool isMajorChangeFrom(HomeWidgetPayload previous) {
    if (super.isMajorChangeFrom(previous)) return true;
    final other = previous as NextDeliveryPayload;
    return other.stopIndex != stopIndex ||
        other.stopCount != stopCount ||
        other.customer != customer ||
        other.address != address;
  }
}
