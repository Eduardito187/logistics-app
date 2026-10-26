// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Lot _$LotFromJson(Map<String, dynamic> json) => Lot(
  id: json['id'] as String,
  warehouseId: json['warehouse_id'] as String,
  sku: json['sku'] as String,
  fulfillmentMode: FulfillmentMode.fromJson(json['fulfillment_mode'] as String),
  ownerPartyId: json['owner_party_id'] as String?,
  sellerSkuRef: json['seller_sku_ref'] as String?,
  availableQuantity: (json['available_quantity'] as num).toInt(),
  reservedQuantity: (json['reserved_quantity'] as num).toInt(),
  onHand: (json['on_hand'] as num).toInt(),
  unitCost: Money.fromJson(json['unit_cost'] as Map<String, dynamic>),
  receivedAt: DateTime.parse(json['received_at'] as String),
  goodsReceiptRef: json['goods_receipt_ref'] as String?,
);

Map<String, dynamic> _$LotToJson(Lot instance) => <String, dynamic>{
  'id': instance.id,
  'warehouse_id': instance.warehouseId,
  'sku': instance.sku,
  'fulfillment_mode': instance.fulfillmentMode,
  'owner_party_id': instance.ownerPartyId,
  'seller_sku_ref': instance.sellerSkuRef,
  'available_quantity': instance.availableQuantity,
  'reserved_quantity': instance.reservedQuantity,
  'on_hand': instance.onHand,
  'unit_cost': instance.unitCost,
  'received_at': instance.receivedAt.toIso8601String(),
  'goods_receipt_ref': instance.goodsReceiptRef,
};
