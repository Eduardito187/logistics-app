// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'import_coverage_map_data.g.dart';

@JsonSerializable()
class ImportCoverageMapData {
  const ImportCoverageMapData({this.status});

  factory ImportCoverageMapData.fromJson(Map<String, Object?> json) =>
      _$ImportCoverageMapDataFromJson(json);

  final String? status;

  Map<String, Object?> toJson() => _$ImportCoverageMapDataToJson(this);
}
