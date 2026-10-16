// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaintenanceOrder _$MaintenanceOrderFromJson(Map<String, dynamic> json) =>
    MaintenanceOrder(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      type: MaintenanceOrderType.fromJson(json['type'] as String),
      status: MaintenanceStatus.fromJson(json['status'] as String),
      items: (json['items'] as List<dynamic>)
          .map((e) => MaintenanceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCostCents: (json['total_cost_cents'] as num).toInt(),
      currency: json['currency'] as String,
      odometerKm: (json['odometer_km'] as num?)?.toInt(),
      workshop: json['workshop'] as String?,
      scheduledAt: json['scheduled_at'] == null
          ? null
          : DateTime.parse(json['scheduled_at'] as String),
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$MaintenanceOrderToJson(MaintenanceOrder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vehicle_id': instance.vehicleId,
      'type': instance.type,
      'status': instance.status,
      'odometer_km': instance.odometerKm,
      'workshop': instance.workshop,
      'items': instance.items,
      'total_cost_cents': instance.totalCostCents,
      'currency': instance.currency,
      'scheduled_at': instance.scheduledAt?.toIso8601String(),
      'started_at': instance.startedAt?.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
      'note': instance.note,
    };
