// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'import_coverage_map_kml_data.g.dart';

@JsonSerializable()
class ImportCoverageMapKmlData {
  const ImportCoverageMapKmlData({this.status});

  factory ImportCoverageMapKmlData.fromJson(Map<String, Object?> json) =>
      _$ImportCoverageMapKmlDataFromJson(json);

  final String? status;

  Map<String, Object?> toJson() => _$ImportCoverageMapKmlDataToJson(this);
}
