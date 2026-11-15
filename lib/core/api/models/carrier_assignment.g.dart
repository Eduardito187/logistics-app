// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'carrier_assignment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarrierAssignment _$CarrierAssignmentFromJson(Map<String, dynamic> json) =>
    CarrierAssignment(
      tripId: json['trip_id'] as String,
      carrierId: json['carrier_id'] as String,
      carrierName: json['carrier_name'] as String?,
      reference: json['reference'] as String?,
      corridorFrom: json['corridor_from'] as String,
      corridorFromNodeId: json['corridor_from_node_id'] as String,
      corridorTo: json['corridor_to'] as String,
      corridorToNodeId: json['corridor_to_node_id'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      status: CarrierTripStatus.fromJson(json['status'] as String),
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      closedAt: json['closed_at'] == null
          ? null
          : DateTime.parse(json['closed_at'] as String),
      shipmentsCount: (json['shipments_count'] as num).toInt(),
      expectedUnitsCount: (json['expected_units_count'] as num).toInt(),
      shipments: (json['shipments'] as List<dynamic>)
          .map(
            (e) =>
                CarrierAssignmentShipment.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$CarrierAssignmentToJson(CarrierAssignment instance) =>
    <String, dynamic>{
      'trip_id': instance.tripId,
      'carrier_id': instance.carrierId,
      'carrier_name': instance.carrierName,
      'reference': instance.reference,
      'corridor_from': instance.corridorFrom,
      'corridor_from_node_id': instance.corridorFromNodeId,
      'corridor_to': instance.corridorTo,
      'corridor_to_node_id': instance.corridorToNodeId,
      'scheduled_at': instance.scheduledAt.toIso8601String(),
      'status': instance.status,
      'started_at': instance.startedAt?.toIso8601String(),
      'closed_at': instance.closedAt?.toIso8601String(),
      'shipments_count': instance.shipmentsCount,
      'expected_units_count': instance.expectedUnitsCount,
      'shipments': instance.shipments,
    };
