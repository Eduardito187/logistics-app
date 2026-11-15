// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'missing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Missing _$MissingFromJson(Map<String, dynamic> json) => Missing(
  unitId: json['unit_id'] as String,
  reason: MissingUnitReason.fromJson(json['reason'] as String),
);

Map<String, dynamic> _$MissingToJson(Missing instance) => <String, dynamic>{
  'unit_id': instance.unitId,
  'reason': instance.reason,
};
