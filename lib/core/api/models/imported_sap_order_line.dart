// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'imported_sap_order_line.g.dart';

@JsonSerializable()
class ImportedSapOrderLine {
  const ImportedSapOrderLine({
    required this.sku,
    required this.productName,
    required this.quantity,
  });

  factory ImportedSapOrderLine.fromJson(Map<String, Object?> json) =>
      _$ImportedSapOrderLineFromJson(json);

  /// SKU propio (traducido desde el material SAP)
  final String sku;
  @JsonKey(name: 'product_name')
  final String productName;
  final int quantity;

  Map<String, Object?> toJson() => _$ImportedSapOrderLineToJson(this);
}
