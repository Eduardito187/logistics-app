// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shipment_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShipmentProgress _$ShipmentProgressFromJson(Map<String, dynamic> json) =>
    ShipmentProgress(
      vehicleId: json['vehicle_id'] as String?,
      plate: json['plate'] as String?,
      assignedAt: json['assigned_at'] == null
          ? null
          : DateTime.parse(json['assigned_at'] as String),
      preparedAt: json['prepared_at'] == null
          ? null
          : DateTime.parse(json['prepared_at'] as String),
      loadedAt: json['loaded_at'] == null
          ? null
          : DateTime.parse(json['loaded_at'] as String),
      deliveredAt: json['delivered_at'] == null
          ? null
          : DateTime.parse(json['delivered_at'] as String),
      labelsEmittedCount: (json['labels_emitted_count'] as num?)?.toInt(),
      executionStatus: json['execution_status'] == null
          ? null
          : ShipmentProgressExecutionStatus.fromJson(
              json['execution_status'] as String,
            ),
      readyForPickupAt: json['ready_for_pickup_at'] == null
          ? null
          : DateTime.parse(json['ready_for_pickup_at'] as String),
    );

Map<String, dynamic> _$ShipmentProgressToJson(ShipmentProgress instance) =>
    <String, dynamic>{
      'vehicle_id': instance.vehicleId,
      'plate': instance.plate,
      'assigned_at': instance.assignedAt?.toIso8601String(),
      'prepared_at': instance.preparedAt?.toIso8601String(),
      'loaded_at': instance.loadedAt?.toIso8601String(),
      'delivered_at': instance.deliveredAt?.toIso8601String(),
      'labels_emitted_count': instance.labelsEmittedCount,
      'ready_for_pickup_at': instance.readyForPickupAt?.toIso8601String(),
      'execution_status': instance.executionStatus,
    };
