// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'due_maintenance_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DueMaintenanceItem _$DueMaintenanceItemFromJson(Map<String, dynamic> json) =>
    DueMaintenanceItem(
      vehicleId: json['vehicle_id'] as String,
      vehiclePlate: json['vehicle_plate'] as String?,
      planId: json['plan_id'] as String?,
      serviceKind: DueMaintenanceItemServiceKind.fromJson(
        json['service_kind'] as String,
      ),
      nextDueKm: (json['next_due_km'] as num?)?.toInt(),
      nextDueAt: json['next_due_at'] == null
          ? null
          : DateTime.parse(json['next_due_at'] as String),
      currentOdometerKm: (json['current_odometer_km'] as num?)?.toInt(),
      remainingKm: (json['remaining_km'] as num?)?.toInt(),
      daysRemaining: (json['days_remaining'] as num?)?.toInt(),
      overdue: json['overdue'] as bool,
      urgency: DueMaintenanceItemUrgency.fromJson(json['urgency'] as String),
    );

Map<String, dynamic> _$DueMaintenanceItemToJson(DueMaintenanceItem instance) =>
    <String, dynamic>{
      'vehicle_id': instance.vehicleId,
      'vehicle_plate': instance.vehiclePlate,
      'plan_id': instance.planId,
      'service_kind': instance.serviceKind,
      'next_due_km': instance.nextDueKm,
      'next_due_at': instance.nextDueAt?.toIso8601String(),
      'current_odometer_km': instance.currentOdometerKm,
      'remaining_km': instance.remainingKm,
      'days_remaining': instance.daysRemaining,
      'overdue': instance.overdue,
      'urgency': instance.urgency,
    };
