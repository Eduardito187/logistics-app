// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'product_physical_spec_input.dart';

part 'items.g.dart';

@JsonSerializable()
class Items {
  const Items({
    required this.sku,
    this.weightKg,
    this.lengthCm,
    this.widthCm,
    this.heightCm,
  });

  factory Items.fromJson(Map<String, Object?> json) => _$ItemsFromJson(json);

  @JsonKey(name: 'weight_kg')
  final num? weightKg;
  @JsonKey(name: 'length_cm')
  final num? lengthCm;
  @JsonKey(name: 'width_cm')
  final num? widthCm;
  @JsonKey(name: 'height_cm')
  final num? heightCm;
  final String sku;

  Map<String, Object?> toJson() => _$ItemsToJson(this);
}
