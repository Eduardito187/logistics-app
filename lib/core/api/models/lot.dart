// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'fulfillment_mode.dart';
import 'money.dart';

part 'lot.g.dart';

@JsonSerializable()
class Lot {
  const Lot({
    required this.id,
    required this.warehouseId,
    required this.sku,
    required this.fulfillmentMode,
    required this.ownerPartyId,
    required this.sellerSkuRef,
    required this.availableQuantity,
    required this.reservedQuantity,
    required this.onHand,
    required this.unitCost,
    required this.receivedAt,
    required this.goodsReceiptRef,
  });

  factory Lot.fromJson(Map<String, Object?> json) => _$LotFromJson(json);

  final String id;
  @JsonKey(name: 'warehouse_id')
  final String warehouseId;
  final String sku;
  @JsonKey(name: 'fulfillment_mode')
  final FulfillmentMode fulfillmentMode;
  @JsonKey(name: 'owner_party_id')
  final String? ownerPartyId;
  @JsonKey(name: 'seller_sku_ref')
  final String? sellerSkuRef;
  @JsonKey(name: 'available_quantity')
  final int availableQuantity;
  @JsonKey(name: 'reserved_quantity')
  final int reservedQuantity;
  @JsonKey(name: 'on_hand')
  final int onHand;
  @JsonKey(name: 'unit_cost')
  final Money unitCost;
  @JsonKey(name: 'received_at')
  final DateTime receivedAt;
  @JsonKey(name: 'goods_receipt_ref')
  final String? goodsReceiptRef;

  Map<String, Object?> toJson() => _$LotToJson(this);
}
