// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'tracking_updated_event_status.dart';

part 'tracking_updated_event.g.dart';

/// Señal `tracking.updated`: el seguimiento de un pedido cambió (estado visible —incluidos cancelado, reprogramado y devuelto—, avance por producto o la ruta que lo transporta). Es una señal para volver a pedir el estado. Viaja por `private-order.{shipment_id}` y por el tema `tracking` (`private-tracking.all` / `private-tracking.city.<departamento>`).
@JsonSerializable()
class TrackingUpdatedEvent {
  const TrackingUpdatedEvent({
    required this.shipmentId,
    required this.status,
    required this.event,
    this.orderReference,
  });

  factory TrackingUpdatedEvent.fromJson(Map<String, Object?> json) =>
      _$TrackingUpdatedEventFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;

  /// Referencia del pedido (agrupa hermanos de multishipping); null si no hay una utilizable.
  @JsonKey(name: 'order_reference')
  final String? orderReference;

  /// Estado visible vigente al emitir la señal.
  final TrackingUpdatedEventStatus status;

  /// Hecho de origen: tracking.status_changed, tracking.shipment_placed_on_route o tracking.unit_status_changed.
  final String event;

  Map<String, Object?> toJson() => _$TrackingUpdatedEventToJson(this);
}
