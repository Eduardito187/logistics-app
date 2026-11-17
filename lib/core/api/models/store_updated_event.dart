// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'store_updated_event.g.dart';

/// Señal `store.updated` (tema store): cambió lo que ve una tienda (el chofer dejó el pedido, recepción de unidades en el nodo, entrega en mostrador, pedido cancelado/reprogramado del nodo). Canales `private-store.all` / `private-store.node.<uuid>`.
@JsonSerializable()
class StoreUpdatedEvent {
  const StoreUpdatedEvent({required this.nodeId, this.shipmentId});

  factory StoreUpdatedEvent.fromJson(Map<String, Object?> json) =>
      _$StoreUpdatedEventFromJson(json);

  @JsonKey(name: 'node_id')
  final String nodeId;

  /// Pista del envío; null = cambio general del nodo.
  @JsonKey(name: 'shipment_id')
  final String? shipmentId;

  Map<String, Object?> toJson() => _$StoreUpdatedEventToJson(this);
}
