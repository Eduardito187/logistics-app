// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'carrier_assignment_shipment.dart';
import 'carrier_trip_status.dart';

part 'carrier_assignment.g.dart';

@JsonSerializable()
class CarrierAssignment {
  const CarrierAssignment({
    required this.tripId,
    required this.carrierId,
    required this.carrierName,
    required this.reference,
    required this.corridorFrom,
    required this.corridorFromNodeId,
    required this.corridorTo,
    required this.corridorToNodeId,
    required this.scheduledAt,
    required this.status,
    required this.startedAt,
    required this.closedAt,
    required this.shipmentsCount,
    required this.expectedUnitsCount,
    required this.shipments,
  });

  factory CarrierAssignment.fromJson(Map<String, Object?> json) =>
      _$CarrierAssignmentFromJson(json);

  @JsonKey(name: 'trip_id')
  final String tripId;
  @JsonKey(name: 'carrier_id')
  final String carrierId;
  @JsonKey(name: 'carrier_name')
  final String? carrierName;
  final String? reference;

  /// Nombre legible del nodo de origen
  @JsonKey(name: 'corridor_from')
  final String corridorFrom;
  @JsonKey(name: 'corridor_from_node_id')
  final String corridorFromNodeId;

  /// Nombre legible del nodo de destino
  @JsonKey(name: 'corridor_to')
  final String corridorTo;
  @JsonKey(name: 'corridor_to_node_id')
  final String corridorToNodeId;
  @JsonKey(name: 'scheduled_at')
  final DateTime scheduledAt;
  final CarrierTripStatus status;
  @JsonKey(name: 'started_at')
  final DateTime? startedAt;
  @JsonKey(name: 'closed_at')
  final DateTime? closedAt;
  @JsonKey(name: 'shipments_count')
  final int shipmentsCount;
  @JsonKey(name: 'expected_units_count')
  final int expectedUnitsCount;
  final List<CarrierAssignmentShipment> shipments;

  Map<String, Object?> toJson() => _$CarrierAssignmentToJson(this);
}
