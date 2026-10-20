// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data13.dart';

part 'post_integrations_coverage_map_import_response.g.dart';

@JsonSerializable()
class PostIntegrationsCoverageMapImportResponse {
  const PostIntegrationsCoverageMapImportResponse({required this.data});

  factory PostIntegrationsCoverageMapImportResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostIntegrationsCoverageMapImportResponseFromJson(json);

  final Data13 data;

  Map<String, Object?> toJson() =>
      _$PostIntegrationsCoverageMapImportResponseToJson(this);
}
