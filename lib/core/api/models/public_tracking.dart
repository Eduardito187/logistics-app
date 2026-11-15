// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'truck_position.dart';
import 'visible_status.dart';

part 'public_tracking.g.dart';

/// Vista pública del seguimiento (sin PII)
@JsonSerializable()
class PublicTracking {
  const PublicTracking({
    required this.status,
    required this.remainingStops,
    required this.routePosition,
    required this.eta,
    required this.lastPosition,
    required this.positionIsLive,
    required this.stopsMessage,
    this.atStoreAt,
    this.readyForPickup,
  });

  factory PublicTracking.fromJson(Map<String, Object?> json) =>
      _$PublicTrackingFromJson(json);

  final VisibleStatus status;

  /// Paradas que el camión atiende antes de llegar a la del cliente
  @JsonKey(name: 'remaining_stops')
  final int remainingStops;

  /// Posición del envío en la secuencia de la ruta publicada (1 es la primera parada)
  @JsonKey(name: 'route_position')
  final int? routePosition;
  final DateTime? eta;
  @JsonKey(name: 'last_position')
  final TruckPosition? lastPosition;

  /// True si la última posición es fresca (ventana en vivo), false si es solo la última conocida, null si no hay posición.
  @JsonKey(name: 'position_is_live')
  final bool? positionIsLive;

  /// Mensaje al cliente en español, p. ej. "Tu pedido está a 3 paradas." Con ready_for_pickup = true vale "Tu pedido ya está en la tienda. Puedes pasar a recogerlo.".
  ///
  @JsonKey(name: 'stops_message')
  final String stopsMessage;

  /// Momento en que un pedido con retiro en tienda llegó a su tienda destino; null si aún no llegó o si el pedido no es de retiro en tienda.
  ///
  @JsonKey(name: 'at_store_at')
  final DateTime? atStoreAt;

  /// True si el pedido ya está en la tienda y el cliente puede pasar a recogerlo (at_store_at no nulo y estado distinto de DELIVERED, CANCELLED y RETURNED). No es un estado nuevo: `status` conserva su valor.
  ///
  @JsonKey(name: 'ready_for_pickup')
  final bool? readyForPickup;

  Map<String, Object?> toJson() => _$PublicTrackingToJson(this);
}
