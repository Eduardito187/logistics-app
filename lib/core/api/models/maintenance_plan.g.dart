// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaintenancePlan _$MaintenancePlanFromJson(Map<String, dynamic> json) =>
    MaintenancePlan(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      serviceKind: MaintenancePlanServiceKind.fromJson(
        json['service_kind'] as String,
      ),
      active: json['active'] as bool,
      intervalKm: (json['interval_km'] as num?)?.toInt(),
      intervalDays: (json['interval_days'] as num?)?.toInt(),
      lastDoneKm: (json['last_done_km'] as num?)?.toInt(),
      lastDoneAt: json['last_done_at'] == null
          ? null
          : DateTime.parse(json['last_done_at'] as String),
      nextDueKm: (json['next_due_km'] as num?)?.toInt(),
      nextDueAt: json['next_due_at'] == null
          ? null
          : DateTime.parse(json['next_due_at'] as String),
    );

Map<String, dynamic> _$MaintenancePlanToJson(MaintenancePlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vehicle_id': instance.vehicleId,
      'service_kind': instance.serviceKind,
      'interval_km': instance.intervalKm,
      'interval_days': instance.intervalDays,
      'last_done_km': instance.lastDoneKm,
      'last_done_at': instance.lastDoneAt?.toIso8601String(),
      'next_due_km': instance.nextDueKm,
      'next_due_at': instance.nextDueAt?.toIso8601String(),
      'active': instance.active,
    };
