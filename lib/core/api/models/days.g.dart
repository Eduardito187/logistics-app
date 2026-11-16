// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'days.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Days _$DaysFromJson(Map<String, dynamic> json) => Days(
  date: json['date'] == null ? null : DateTime.parse(json['date'] as String),
  municipalityId: json['municipality_id'] as String?,
  blocked: json['blocked'] as bool?,
  reason: json['reason'] as String?,
  withinHorizon: json['within_horizon'] as bool?,
  activeUntil: json['active_until'] == null
      ? null
      : DateTime.parse(json['active_until'] as String),
  available: json['available'] as bool?,
  capacityTotal: json['capacity_total'] as num?,
  capacityUsed: json['capacity_used'] as num?,
);

Map<String, dynamic> _$DaysToJson(Days instance) => <String, dynamic>{
  'date': instance.date?.toIso8601String(),
  'municipality_id': instance.municipalityId,
  'blocked': instance.blocked,
  'reason': instance.reason,
  'within_horizon': instance.withinHorizon,
  'active_until': instance.activeUntil?.toIso8601String(),
  'available': instance.available,
  'capacity_total': instance.capacityTotal,
  'capacity_used': instance.capacityUsed,
};
