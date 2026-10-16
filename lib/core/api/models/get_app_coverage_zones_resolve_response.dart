// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'coverage_zone.dart';

part 'get_app_coverage_zones_resolve_response.g.dart';

@JsonSerializable()
class GetAppCoverageZonesResolveResponse {
  const GetAppCoverageZonesResolveResponse({required this.data});

  factory GetAppCoverageZonesResolveResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppCoverageZonesResolveResponseFromJson(json);

  final CoverageZone data;

  Map<String, Object?> toJson() =>
      _$GetAppCoverageZonesResolveResponseToJson(this);
}
