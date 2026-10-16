// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'truck_position.dart';
import 'visible_status.dart';

part 'shipment_tracking.g.dart';

/// Vista interna del seguimiento (incluye claves internas)
@JsonSerializable()
class ShipmentTracking {
  const ShipmentTracking({
    required this.id,
    required this.shipmentId,
    required this.token,
    required this.status,
    required this.remainingStops,
    required this.routePosition,
    required this.eta,
    required this.lastPosition,
    required this.positionIsLive,
    this.shipmentExternalId,
  });

  factory ShipmentTracking.fromJson(Map<String, Object?> json) =>
      _$ShipmentTrackingFromJson(json);

  final String id;
  @JsonKey(name: 'shipment_id')
  final String shipmentId;

  /// Referencia externa humana del envío (shipments.external_id)
  @JsonKey(name: 'shipment_external_id')
  final String? shipmentExternalId;
  final String token;
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

  /// True si la última posición es fresca, false si es solo la última conocida, null si no hay posición.
  @JsonKey(name: 'position_is_live')
  final bool? positionIsLive;

  Map<String, Object?> toJson() => _$ShipmentTrackingToJson(this);
}
