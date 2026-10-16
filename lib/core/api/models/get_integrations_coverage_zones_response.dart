// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'coverage_zone.dart';

part 'get_integrations_coverage_zones_response.g.dart';

@JsonSerializable()
class GetIntegrationsCoverageZonesResponse {
  const GetIntegrationsCoverageZonesResponse({required this.data});

  factory GetIntegrationsCoverageZonesResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetIntegrationsCoverageZonesResponseFromJson(json);

  final List<CoverageZone> data;

  Map<String, Object?> toJson() =>
      _$GetIntegrationsCoverageZonesResponseToJson(this);
}
