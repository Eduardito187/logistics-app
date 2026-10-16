// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_node_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterNodeRequest _$RegisterNodeRequestFromJson(Map<String, dynamic> json) =>
    RegisterNodeRequest(
      code: json['code'] as String,
      name: json['name'] as String,
      type: NodeType.fromJson(json['type'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      department: json['department'] == null
          ? null
          : Department.fromJson(json['department'] as String),
    );

Map<String, dynamic> _$RegisterNodeRequestToJson(
  RegisterNodeRequest instance,
) => <String, dynamic>{
  'code': instance.code,
  'name': instance.name,
  'type': instance.type,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'department': instance.department,
};
