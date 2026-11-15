// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'product_physical_spec.g.dart';

@JsonSerializable()
class ProductPhysicalSpec {
  const ProductPhysicalSpec({
    this.weightKg,
    this.lengthCm,
    this.widthCm,
    this.heightCm,
    this.volumeM3,
  });

  factory ProductPhysicalSpec.fromJson(Map<String, Object?> json) =>
      _$ProductPhysicalSpecFromJson(json);

  @JsonKey(name: 'weight_kg')
  final num? weightKg;
  @JsonKey(name: 'length_cm')
  final num? lengthCm;
  @JsonKey(name: 'width_cm')
  final num? widthCm;
  @JsonKey(name: 'height_cm')
  final num? heightCm;

  /// Derived from the three dimensions when all are present.
  @JsonKey(name: 'volume_m3')
  final num? volumeM3;

  Map<String, Object?> toJson() => _$ProductPhysicalSpecToJson(this);
}
