// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'open_node_reception_request_destination_node_kind.dart';
import 'open_node_reception_request_origin_node_kind.dart';

part 'open_node_reception_request.g.dart';

/// Abre la recepción de un envío en un nodo destino por un corredor interno. Basta {shipment_id, occurred_at}: el servidor deriva origen, destino (destination_node_id del envío o el nodo del usuario), tipos de nodo y expected_unit_ids. El cuerpo completo anterior sigue aceptándose.
@JsonSerializable()
class OpenNodeReceptionRequest {
  const OpenNodeReceptionRequest({
    required this.shipmentId,
    required this.occurredAt,
    this.originNodeId,
    this.destinationNodeId,
    this.originNodeKind,
    this.destinationNodeKind,
    this.expectedUnitIds,
  });

  factory OpenNodeReceptionRequest.fromJson(Map<String, Object?> json) =>
      _$OpenNodeReceptionRequestFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  @JsonKey(name: 'origin_node_id')
  final String? originNodeId;

  /// Debe ser distinto del nodo de origen
  @JsonKey(name: 'destination_node_id')
  final String? destinationNodeId;
  @JsonKey(name: 'origin_node_kind')
  final OpenNodeReceptionRequestOriginNodeKind? originNodeKind;
  @JsonKey(name: 'destination_node_kind')
  final OpenNodeReceptionRequestDestinationNodeKind? destinationNodeKind;

  /// Productos esperados en este nodo
  @JsonKey(name: 'expected_unit_ids')
  final List<String>? expectedUnitIds;
  @JsonKey(name: 'occurred_at')
  final DateTime occurredAt;

  Map<String, Object?> toJson() => _$OpenNodeReceptionRequestToJson(this);
}
