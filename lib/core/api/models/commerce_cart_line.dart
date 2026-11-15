// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'commerce_cart_line.g.dart';

@JsonSerializable()
class CommerceCartLine {
  const CommerceCartLine({
    required this.sku,
    required this.productName,
    required this.unitPriceCents,
    required this.qty,
    required this.subtotalCents,
  });

  factory CommerceCartLine.fromJson(Map<String, Object?> json) =>
      _$CommerceCartLineFromJson(json);

  final String sku;
  @JsonKey(name: 'product_name')
  final String productName;
  @JsonKey(name: 'unit_price_cents')
  final int unitPriceCents;
  final int qty;
  @JsonKey(name: 'subtotal_cents')
  final int subtotalCents;

  Map<String, Object?> toJson() => _$CommerceCartLineToJson(this);
}
