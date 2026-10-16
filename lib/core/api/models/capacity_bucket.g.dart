// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capacity_bucket.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CapacityBucket _$CapacityBucketFromJson(Map<String, dynamic> json) =>
    CapacityBucket(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      timeSlot: json['time_slot'] as String,
      unit: CapacityUnit.fromJson(json['unit'] as String),
      total: (json['total'] as num).toDouble(),
      used: (json['used'] as num).toDouble(),
      available: (json['available'] as num).toDouble(),
      full: json['full'] as bool,
      nodeId: json['node_id'] as String?,
      zoneId: json['zone_id'] as String?,
      municipalityId: json['municipality_id'] as String?,
    );

Map<String, dynamic> _$CapacityBucketToJson(CapacityBucket instance) =>
    <String, dynamic>{
      'id': instance.id,
      'node_id': instance.nodeId,
      'zone_id': instance.zoneId,
      'municipality_id': instance.municipalityId,
      'date': instance.date.toIso8601String(),
      'time_slot': instance.timeSlot,
      'unit': instance.unit,
      'total': instance.total,
      'used': instance.used,
      'available': instance.available,
      'full': instance.full,
    };
