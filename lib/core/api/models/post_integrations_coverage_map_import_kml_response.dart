// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data13.dart';

part 'post_integrations_coverage_map_import_kml_response.g.dart';

@JsonSerializable()
class PostIntegrationsCoverageMapImportKmlResponse {
  const PostIntegrationsCoverageMapImportKmlResponse({required this.data});

  factory PostIntegrationsCoverageMapImportKmlResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostIntegrationsCoverageMapImportKmlResponseFromJson(json);

  final Data13 data;

  Map<String, Object?> toJson() =>
      _$PostIntegrationsCoverageMapImportKmlResponseToJson(this);
}
