// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_coverage_zones_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppCoverageZonesResponse _$GetAppCoverageZonesResponseFromJson(
  Map<String, dynamic> json,
) => GetAppCoverageZonesResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => CoverageZone.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetAppCoverageZonesResponseToJson(
  GetAppCoverageZonesResponse instance,
) => <String, dynamic>{'data': instance.data};
