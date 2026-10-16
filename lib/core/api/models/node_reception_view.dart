// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'node_reception_view_corridor.dart';
import 'node_reception_view_status.dart';

part 'node_reception_view.g.dart';

/// Read model of a node reception (flat primitives) with the reconciliation result.
@JsonSerializable()
class NodeReceptionView {
  const NodeReceptionView({
    required this.id,
    required this.shipmentId,
    required this.originNodeId,
    required this.destinationNodeId,
    required this.corridor,
    required this.status,
    required this.expectedUnitIds,
    required this.receivedUnitIds,
    required this.missingUnitIds,
    required this.surplusUnitIds,
    required this.expectedCount,
    required this.receivedCount,
    required this.complete,
    required this.openedAt,
    this.reconciledAt,
  });

  factory NodeReceptionView.fromJson(Map<String, Object?> json) =>
      _$NodeReceptionViewFromJson(json);

  final String id;
  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  @JsonKey(name: 'origin_node_id')
  final String originNodeId;
  @JsonKey(name: 'destination_node_id')
  final String destinationNodeId;
  final NodeReceptionViewCorridor corridor;
  final NodeReceptionViewStatus status;
  @JsonKey(name: 'expected_unit_ids')
  final List<String> expectedUnitIds;
  @JsonKey(name: 'received_unit_ids')
  final List<String> receivedUnitIds;

  /// Bultos esperados que no se recibieron
  @JsonKey(name: 'missing_unit_ids')
  final List<String> missingUnitIds;

  /// Bultos recibidos que no se esperaban
  @JsonKey(name: 'surplus_unit_ids')
  final List<String> surplusUnitIds;
  @JsonKey(name: 'expected_count')
  final int expectedCount;
  @JsonKey(name: 'received_count')
  final int receivedCount;

  /// Verdadero si no hay faltantes ni sobrantes
  final bool complete;
  @JsonKey(name: 'opened_at')
  final DateTime openedAt;
  @JsonKey(name: 'reconciled_at')
  final DateTime? reconciledAt;

  Map<String, Object?> toJson() => _$NodeReceptionViewToJson(this);
}
