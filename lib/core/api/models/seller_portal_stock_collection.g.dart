// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_portal_stock_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SellerPortalStockCollection _$SellerPortalStockCollectionFromJson(
  Map<String, dynamic> json,
) => SellerPortalStockCollection(
  sellerId: json['seller_id'] as String,
  data: (json['data'] as List<dynamic>)
      .map((e) => SellerPortalStockLot.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SellerPortalStockCollectionToJson(
  SellerPortalStockCollection instance,
) => <String, dynamic>{'seller_id': instance.sellerId, 'data': instance.data};
