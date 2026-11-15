// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_product_media.dart';
import 'commerce_product_status.dart';
import 'commerce_product_variant.dart';
import 'product_physical_spec.dart';

part 'commerce_product.g.dart';

@JsonSerializable()
class CommerceProduct {
  const CommerceProduct({
    required this.id,
    required this.name,
    required this.canonicalSku,
    required this.status,
    required this.variants,
    required this.media,
    this.physicalSpec,
    this.sellerId,
    this.categoryId,
    this.description,
  });

  factory CommerceProduct.fromJson(Map<String, Object?> json) =>
      _$CommerceProductFromJson(json);

  @JsonKey(name: 'physical_spec')
  final ProductPhysicalSpec? physicalSpec;
  final String id;

  /// Owning seller (null = Dismac-owned/retail, ADR 017).
  @JsonKey(name: 'seller_id')
  final String? sellerId;
  @JsonKey(name: 'category_id')
  final String? categoryId;
  final String name;
  final String? description;

  /// Canonical SKU; the 1:1 bridge to inventory (ATP).
  @JsonKey(name: 'canonical_sku')
  final String canonicalSku;
  final CommerceProductStatus status;
  final List<CommerceProductVariant> variants;
  final List<CommerceProductMedia> media;

  Map<String, Object?> toJson() => _$CommerceProductToJson(this);
}
