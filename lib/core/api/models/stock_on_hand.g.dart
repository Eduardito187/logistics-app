// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_on_hand.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockOnHand _$StockOnHandFromJson(Map<String, dynamic> json) => StockOnHand(
  fulfillmentMode: FulfillmentMode.fromJson(json['fulfillment_mode'] as String),
  ownerPartyId: json['owner_party_id'] as String?,
  available: (json['available'] as num).toInt(),
  reserved: (json['reserved'] as num).toInt(),
  onHand: (json['on_hand'] as num).toInt(),
  lots: (json['lots'] as num).toInt(),
);

Map<String, dynamic> _$StockOnHandToJson(StockOnHand instance) =>
    <String, dynamic>{
      'fulfillment_mode': instance.fulfillmentMode,
      'owner_party_id': instance.ownerPartyId,
      'available': instance.available,
      'reserved': instance.reserved,
      'on_hand': instance.onHand,
      'lots': instance.lots,
    };
