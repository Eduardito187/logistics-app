// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'carrier_assignment_unit.dart';

part 'carrier_assignment_shipment.g.dart';

@JsonSerializable()
class CarrierAssignmentShipment {
  const CarrierAssignmentShipment({
    required this.shipmentId,
    required this.externalId,
    required this.orderReference,
    required this.customerName,
    required this.destinationNode,
    required this.destinationNodeId,
    required this.unitsCount,
    required this.units,
  });

  factory CarrierAssignmentShipment.fromJson(Map<String, Object?> json) =>
      _$CarrierAssignmentShipmentFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  @JsonKey(name: 'external_id')
  final String externalId;
  @JsonKey(name: 'order_reference')
  final String? orderReference;
  @JsonKey(name: 'customer_name')
  final String customerName;

  /// Nombre legible; null = domicilio del cliente.
  @JsonKey(name: 'destination_node')
  final String? destinationNode;
  @JsonKey(name: 'destination_node_id')
  final String? destinationNodeId;
  @JsonKey(name: 'units_count')
  final int unitsCount;
  final List<CarrierAssignmentUnit> units;

  Map<String, Object?> toJson() => _$CarrierAssignmentShipmentToJson(this);
}
