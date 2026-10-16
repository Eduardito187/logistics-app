// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coverage_zone.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoverageZone _$CoverageZoneFromJson(Map<String, dynamic> json) => CoverageZone(
  id: json['id'] as String,
  name: json['name'] as String,
  parentAreaId: json['parentAreaId'] as String?,
  active: json['active'] as bool,
  polygon: GeoJsonPolygon.fromJson(json['polygon'] as Map<String, dynamic>),
  rules: CoverageRule.fromJson(json['rules'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CoverageZoneToJson(CoverageZone instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'parentAreaId': instance.parentAreaId,
      'active': instance.active,
      'polygon': instance.polygon,
      'rules': instance.rules,
    };
