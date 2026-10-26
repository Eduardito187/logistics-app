// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'return_disposition.dart';
import 'return_fulfillment_mode.dart';
import 'return_line.dart';
import 'return_order_kind.dart';
import 'return_order_status.dart';

part 'return_order.g.dart';

@JsonSerializable()
class ReturnOrder {
  const ReturnOrder({
    required this.id,
    required this.originalReference,
    required this.sellerId,
    required this.warehouseId,
    required this.fulfillmentMode,
    required this.kind,
    required this.disposition,
    required this.status,
    required this.lines,
  });

  factory ReturnOrder.fromJson(Map<String, Object?> json) =>
      _$ReturnOrderFromJson(json);

  final String id;
  @JsonKey(name: 'original_reference')
  final String originalReference;
  @JsonKey(name: 'seller_id')
  final String? sellerId;
  @JsonKey(name: 'warehouse_id')
  final String warehouseId;
  @JsonKey(name: 'fulfillment_mode')
  final ReturnFulfillmentMode fulfillmentMode;
  final ReturnOrderKind kind;
  final ReturnDisposition? disposition;
  final ReturnOrderStatus status;
  final List<ReturnLine> lines;

  Map<String, Object?> toJson() => _$ReturnOrderToJson(this);
}
