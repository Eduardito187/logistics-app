// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'commerce_order_line.g.dart';

@JsonSerializable()
class CommerceOrderLine {
  const CommerceOrderLine({
    required this.sku,
    required this.productName,
    required this.unitPriceCents,
    required this.quantity,
  });

  factory CommerceOrderLine.fromJson(Map<String, Object?> json) =>
      _$CommerceOrderLineFromJson(json);

  final String sku;
  @JsonKey(name: 'product_name')
  final String productName;
  @JsonKey(name: 'unit_price_cents')
  final int unitPriceCents;
  final int quantity;

  Map<String, Object?> toJson() => _$CommerceOrderLineToJson(this);
}
