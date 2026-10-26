// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'seller_portal_stock_lot_fulfillment_mode.dart';

part 'seller_portal_stock_lot.g.dart';

@JsonSerializable()
class SellerPortalStockLot {
  const SellerPortalStockLot({
    required this.id,
    required this.ownerPartyId,
    required this.warehouseId,
    required this.sku,
    required this.fulfillmentMode,
    required this.availableQuantity,
    required this.reservedQuantity,
    required this.unitCostCents,
    required this.currency,
    this.sellerSkuRef,
    this.receivedAt,
    this.goodsReceiptRef,
  });

  factory SellerPortalStockLot.fromJson(Map<String, Object?> json) =>
      _$SellerPortalStockLotFromJson(json);

  final String id;
  @JsonKey(name: 'owner_party_id')
  final String ownerPartyId;
  @JsonKey(name: 'warehouse_id')
  final String warehouseId;
  final String sku;
  @JsonKey(name: 'fulfillment_mode')
  final SellerPortalStockLotFulfillmentMode fulfillmentMode;
  @JsonKey(name: 'seller_sku_ref')
  final String? sellerSkuRef;
  @JsonKey(name: 'available_quantity')
  final int availableQuantity;
  @JsonKey(name: 'reserved_quantity')
  final int reservedQuantity;
  @JsonKey(name: 'unit_cost_cents')
  final int unitCostCents;
  final String currency;
  @JsonKey(name: 'received_at')
  final DateTime? receivedAt;
  @JsonKey(name: 'goods_receipt_ref')
  final String? goodsReceiptRef;

  Map<String, Object?> toJson() => _$SellerPortalStockLotToJson(this);
}
