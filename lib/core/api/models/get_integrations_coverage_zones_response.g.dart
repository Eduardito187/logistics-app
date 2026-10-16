// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_integrations_coverage_zones_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetIntegrationsCoverageZonesResponse
_$GetIntegrationsCoverageZonesResponseFromJson(Map<String, dynamic> json) =>
    GetIntegrationsCoverageZonesResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => CoverageZone.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GetIntegrationsCoverageZonesResponseToJson(
  GetIntegrationsCoverageZonesResponse instance,
) => <String, dynamic>{'data': instance.data};
