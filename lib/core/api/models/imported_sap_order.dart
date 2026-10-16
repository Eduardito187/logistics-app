// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'imported_sap_order_line.dart';

part 'imported_sap_order.g.dart';

@JsonSerializable()
class ImportedSapOrder {
  const ImportedSapOrder({
    required this.externalId,
    required this.customerName,
    required this.addressText,
    required this.lines,
    this.addressReference,
  });

  factory ImportedSapOrder.fromJson(Map<String, Object?> json) =>
      _$ImportedSapOrderFromJson(json);

  @JsonKey(name: 'external_id')
  final String externalId;
  @JsonKey(name: 'customer_name')
  final String customerName;
  @JsonKey(name: 'address_text')
  final String addressText;
  @JsonKey(name: 'address_reference')
  final String? addressReference;
  final List<ImportedSapOrderLine> lines;

  Map<String, Object?> toJson() => _$ImportedSapOrderToJson(this);
}
