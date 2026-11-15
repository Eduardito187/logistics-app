// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'captured_location.dart';

part 'receive_unit_at_node_request.g.dart';

/// Recepción de un producto en el nodo. Sin señal se omite la posición (nunca 0,0).
@JsonSerializable()
class ReceiveUnitAtNodeRequest {
  const ReceiveUnitAtNodeRequest({
    required this.shipmentId,
    required this.unitId,
    required this.destinationNodeId,
    required this.occurredAt,
    this.lat,
    this.lng,
    this.location,
    this.deviceId,
    this.userId,
    this.idempotencyKey,
  });

  factory ReceiveUnitAtNodeRequest.fromJson(Map<String, Object?> json) =>
      _$ReceiveUnitAtNodeRequestFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  @JsonKey(name: 'unit_id')
  final String unitId;

  /// Nodo destino donde se recibe el producto
  @JsonKey(name: 'destination_node_id')
  final String destinationNodeId;

  /// Se manda junto con lng.
  final double? lat;
  final double? lng;
  final CapturedLocation? location;
  @JsonKey(name: 'occurred_at')
  final DateTime occurredAt;
  @JsonKey(name: 'device_id')
  final String? deviceId;
  @JsonKey(name: 'user_id')
  final String? userId;
  @JsonKey(name: 'idempotency_key')
  final String? idempotencyKey;

  Map<String, Object?> toJson() => _$ReceiveUnitAtNodeRequestToJson(this);
}
