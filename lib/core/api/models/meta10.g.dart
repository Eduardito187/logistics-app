// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meta10.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Meta10 _$Meta10FromJson(Map<String, dynamic> json) => Meta10(
  count: (json['count'] as num?)?.toInt(),
  accepted: (json['accepted'] as num?)?.toInt(),
  duplicate: (json['duplicate'] as num?)?.toInt(),
  rejected: (json['rejected'] as num?)?.toInt(),
);

Map<String, dynamic> _$Meta10ToJson(Meta10 instance) => <String, dynamic>{
  'count': instance.count,
  'accepted': instance.accepted,
  'duplicate': instance.duplicate,
  'rejected': instance.rejected,
};
