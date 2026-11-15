// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'reception.dart';

part 'node_reception_summary.g.dart';

@JsonSerializable()
class NodeReceptionSummary {
  const NodeReceptionSummary({
    this.id,
    this.shipmentId,
    this.orderReference,
    this.customerName,
    this.originNodeId,
    this.destinationNodeId,
    this.corridor,
    this.reception,
  });

  factory NodeReceptionSummary.fromJson(Map<String, Object?> json) =>
      _$NodeReceptionSummaryFromJson(json);

  final String? id;
  @JsonKey(name: 'shipment_id')
  final String? shipmentId;
  @JsonKey(name: 'order_reference')
  final String? orderReference;
  @JsonKey(name: 'customer_name')
  final String? customerName;
  @JsonKey(name: 'origin_node_id')
  final String? originNodeId;
  @JsonKey(name: 'destination_node_id')
  final String? destinationNodeId;
  final String? corridor;
  final Reception? reception;

  Map<String, Object?> toJson() => _$NodeReceptionSummaryToJson(this);
}
