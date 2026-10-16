// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'shipment_line.g.dart';

@JsonSerializable()
class ShipmentLine {
  const ShipmentLine({
    required this.id,
    required this.sku,
    required this.productName,
    required this.quantity,
  });

  factory ShipmentLine.fromJson(Map<String, Object?> json) =>
      _$ShipmentLineFromJson(json);

  final String id;
  final String sku;
  @JsonKey(name: 'product_name')
  final String productName;
  final int quantity;

  Map<String, Object?> toJson() => _$ShipmentLineToJson(this);
}
