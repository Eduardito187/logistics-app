// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'receive_shipment_line.g.dart';

@JsonSerializable()
class ReceiveShipmentLine {
  const ReceiveShipmentLine({
    required this.sku,
    required this.productName,
    required this.quantity,
  });

  factory ReceiveShipmentLine.fromJson(Map<String, Object?> json) =>
      _$ReceiveShipmentLineFromJson(json);

  final String sku;
  @JsonKey(name: 'product_name')
  final String productName;
  final int quantity;

  Map<String, Object?> toJson() => _$ReceiveShipmentLineToJson(this);
}
