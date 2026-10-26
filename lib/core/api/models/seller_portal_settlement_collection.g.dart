// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_portal_settlement_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SellerPortalSettlementCollection _$SellerPortalSettlementCollectionFromJson(
  Map<String, dynamic> json,
) => SellerPortalSettlementCollection(
  sellerId: json['seller_id'] as String,
  data: (json['data'] as List<dynamic>)
      .map((e) => SellerPortalSettlement.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SellerPortalSettlementCollectionToJson(
  SellerPortalSettlementCollection instance,
) => <String, dynamic>{'seller_id': instance.sellerId, 'data': instance.data};
