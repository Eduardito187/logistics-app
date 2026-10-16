// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'open_node_reception_request_destination_node_kind.dart';
import 'open_node_reception_request_origin_node_kind.dart';

part 'open_node_reception_request.g.dart';

/// Abre la recepción de un envío en un nodo destino por un corredor interno.
@JsonSerializable()
class OpenNodeReceptionRequest {
  const OpenNodeReceptionRequest({
    required this.shipmentId,
    required this.originNodeId,
    required this.destinationNodeId,
    required this.originNodeKind,
    required this.destinationNodeKind,
    required this.expectedUnitIds,
    required this.occurredAt,
  });

  factory OpenNodeReceptionRequest.fromJson(Map<String, Object?> json) =>
      _$OpenNodeReceptionRequestFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  @JsonKey(name: 'origin_node_id')
  final String originNodeId;

  /// Debe ser distinto del nodo de origen
  @JsonKey(name: 'destination_node_id')
  final String destinationNodeId;
  @JsonKey(name: 'origin_node_kind')
  final OpenNodeReceptionRequestOriginNodeKind originNodeKind;
  @JsonKey(name: 'destination_node_kind')
  final OpenNodeReceptionRequestDestinationNodeKind destinationNodeKind;

  /// Bultos esperados en este nodo
  @JsonKey(name: 'expected_unit_ids')
  final List<String> expectedUnitIds;
  @JsonKey(name: 'occurred_at')
  final DateTime occurredAt;

  Map<String, Object?> toJson() => _$OpenNodeReceptionRequestToJson(this);
}
