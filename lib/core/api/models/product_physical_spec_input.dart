// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'product_physical_spec_input.g.dart';

/// At least one field is required; values must be positive (weight in kg, dimensions in cm).
@JsonSerializable()
class ProductPhysicalSpecInput {
  const ProductPhysicalSpecInput({
    this.weightKg,
    this.lengthCm,
    this.widthCm,
    this.heightCm,
  });

  factory ProductPhysicalSpecInput.fromJson(Map<String, Object?> json) =>
      _$ProductPhysicalSpecInputFromJson(json);

  @JsonKey(name: 'weight_kg')
  final num? weightKg;
  @JsonKey(name: 'length_cm')
  final num? lengthCm;
  @JsonKey(name: 'width_cm')
  final num? widthCm;
  @JsonKey(name: 'height_cm')
  final num? heightCm;

  Map<String, Object?> toJson() => _$ProductPhysicalSpecInputToJson(this);
}
