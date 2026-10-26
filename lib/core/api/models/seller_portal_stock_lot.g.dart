// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_portal_stock_lot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SellerPortalStockLot _$SellerPortalStockLotFromJson(
  Map<String, dynamic> json,
) => SellerPortalStockLot(
  id: json['id'] as String,
  ownerPartyId: json['owner_party_id'] as String,
  warehouseId: json['warehouse_id'] as String,
  sku: json['sku'] as String,
  fulfillmentMode: SellerPortalStockLotFulfillmentMode.fromJson(
    json['fulfillment_mode'] as String,
  ),
  availableQuantity: (json['available_quantity'] as num).toInt(),
  reservedQuantity: (json['reserved_quantity'] as num).toInt(),
  unitCostCents: (json['unit_cost_cents'] as num).toInt(),
  currency: json['currency'] as String,
  sellerSkuRef: json['seller_sku_ref'] as String?,
  receivedAt: json['received_at'] == null
      ? null
      : DateTime.parse(json['received_at'] as String),
  goodsReceiptRef: json['goods_receipt_ref'] as String?,
);

Map<String, dynamic> _$SellerPortalStockLotToJson(
  SellerPortalStockLot instance,
) => <String, dynamic>{
  'id': instance.id,
  'owner_party_id': instance.ownerPartyId,
  'warehouse_id': instance.warehouseId,
  'sku': instance.sku,
  'fulfillment_mode': instance.fulfillmentMode,
  'seller_sku_ref': instance.sellerSkuRef,
  'available_quantity': instance.availableQuantity,
  'reserved_quantity': instance.reservedQuantity,
  'unit_cost_cents': instance.unitCostCents,
  'currency': instance.currency,
  'received_at': instance.receivedAt?.toIso8601String(),
  'goods_receipt_ref': instance.goodsReceiptRef,
};
