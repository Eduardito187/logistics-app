// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geofence.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Geofence _$GeofenceFromJson(Map<String, dynamic> json) => Geofence(
  id: json['id'] as String,
  name: json['name'] as String,
  type: GeofenceType.fromJson(json['type'] as String),
  polygon: (json['polygon'] as List<dynamic>)
      .map((e) => GeoPoint.fromJson(e as Map<String, dynamic>))
      .toList(),
  active: json['active'] as bool,
  nodeRef: json['node_ref'] as String?,
);

Map<String, dynamic> _$GeofenceToJson(Geofence instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': instance.type,
  'polygon': instance.polygon,
  'active': instance.active,
  'node_ref': instance.nodeRef,
};
