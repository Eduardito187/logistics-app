// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'reconcile_node_reception_request.g.dart';

/// Cierra la recepción conciliando lo recibido contra lo esperado.
@JsonSerializable()
class ReconcileNodeReceptionRequest {
  const ReconcileNodeReceptionRequest({
    required this.shipmentId,
    required this.destinationNodeId,
    required this.occurredAt,
    this.deviceId,
    this.userId,
  });

  factory ReconcileNodeReceptionRequest.fromJson(Map<String, Object?> json) =>
      _$ReconcileNodeReceptionRequestFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  @JsonKey(name: 'destination_node_id')
  final String destinationNodeId;
  @JsonKey(name: 'occurred_at')
  final DateTime occurredAt;

  /// Puede inyectarlo el token de Auth; opcional en el cuerpo
  @JsonKey(name: 'device_id')
  final String? deviceId;

  /// Puede inyectarlo el token de Auth; opcional en el cuerpo
  @JsonKey(name: 'user_id')
  final String? userId;

  Map<String, Object?> toJson() => _$ReconcileNodeReceptionRequestToJson(this);
}
