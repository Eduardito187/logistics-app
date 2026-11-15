// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'commerce_add_item_request.g.dart';

@JsonSerializable()
class CommerceAddItemRequest {
  const CommerceAddItemRequest({
    required this.sku,
    required this.productName,
    required this.unitPriceCents,
    this.quantity = 1,
  });

  factory CommerceAddItemRequest.fromJson(Map<String, Object?> json) =>
      _$CommerceAddItemRequestFromJson(json);

  final String sku;
  @JsonKey(name: 'product_name')
  final String productName;

  /// Unit price in cents, already resolved by the storefront.
  @JsonKey(name: 'unit_price_cents')
  final int unitPriceCents;
  final int quantity;

  Map<String, Object?> toJson() => _$CommerceAddItemRequestToJson(this);
}
