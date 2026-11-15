// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'product_physical_spec.dart';

part 'set_product_physical_spec_data.g.dart';

@JsonSerializable()
class SetProductPhysicalSpecData {
  const SetProductPhysicalSpecData({
    this.canonicalSku,
    this.name,
    this.physicalSpec,
  });

  factory SetProductPhysicalSpecData.fromJson(Map<String, Object?> json) =>
      _$SetProductPhysicalSpecDataFromJson(json);

  @JsonKey(name: 'canonical_sku')
  final String? canonicalSku;
  final String? name;
  @JsonKey(name: 'physical_spec')
  final ProductPhysicalSpec? physicalSpec;

  Map<String, Object?> toJson() => _$SetProductPhysicalSpecDataToJson(this);
}
