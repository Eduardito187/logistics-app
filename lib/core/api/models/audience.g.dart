// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audience.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Audience _$AudienceFromJson(Map<String, dynamic> json) => Audience(
  role: json['role'] == null
      ? null
      : StaffRoleName.fromJson(json['role'] as String),
  nodeId: json['node_id'] as String?,
  userIds: (json['user_ids'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$AudienceToJson(Audience instance) => <String, dynamic>{
  'role': instance.role,
  'node_id': instance.nodeId,
  'user_ids': instance.userIds,
};
