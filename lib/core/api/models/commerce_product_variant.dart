// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'commerce_product_variant.g.dart';

@JsonSerializable()
class CommerceProductVariant {
  const CommerceProductVariant({
    required this.sku,
    required this.name,
    required this.attributes,
  });

  factory CommerceProductVariant.fromJson(Map<String, Object?> json) =>
      _$CommerceProductVariantFromJson(json);

  final String sku;
  final String name;
  final Map<String, String> attributes;

  Map<String, Object?> toJson() => _$CommerceProductVariantToJson(this);
}
