// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assign_shelf_location_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssignShelfLocationRequest _$AssignShelfLocationRequestFromJson(
  Map<String, dynamic> json,
) => AssignShelfLocationRequest(
  nodeId: json['node_id'] as String,
  location: json['location'] as String,
  occurredAt: DateTime.parse(json['occurred_at'] as String),
  unitIds: (json['unit_ids'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$AssignShelfLocationRequestToJson(
  AssignShelfLocationRequest instance,
) => <String, dynamic>{
  'node_id': instance.nodeId,
  'location': instance.location,
  'occurred_at': instance.occurredAt.toIso8601String(),
  'unit_ids': instance.unitIds,
};
