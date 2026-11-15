// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'results.dart';
import 'summary.dart';

part 'batch_set_product_physical_specs_data.g.dart';

@JsonSerializable()
class BatchSetProductPhysicalSpecsData {
  const BatchSetProductPhysicalSpecsData({this.results, this.summary});

  factory BatchSetProductPhysicalSpecsData.fromJson(
    Map<String, Object?> json,
  ) => _$BatchSetProductPhysicalSpecsDataFromJson(json);

  final List<Results>? results;
  final Summary? summary;

  Map<String, Object?> toJson() =>
      _$BatchSetProductPhysicalSpecsDataToJson(this);
}
