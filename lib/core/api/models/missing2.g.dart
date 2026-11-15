// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'missing2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Missing2 _$Missing2FromJson(Map<String, dynamic> json) => Missing2(
  unitId: json['unit_id'] as String?,
  reason: json['reason'] == null
      ? null
      : Reason2.fromJson(json['reason'] as String),
);

Map<String, dynamic> _$Missing2ToJson(Missing2 instance) => <String, dynamic>{
  'unit_id': instance.unitId,
  'reason': instance.reason,
};
