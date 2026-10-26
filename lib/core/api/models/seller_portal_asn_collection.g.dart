// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_portal_asn_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SellerPortalAsnCollection _$SellerPortalAsnCollectionFromJson(
  Map<String, dynamic> json,
) => SellerPortalAsnCollection(
  sellerId: json['seller_id'] as String,
  data: (json['data'] as List<dynamic>)
      .map((e) => SellerPortalAsn.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SellerPortalAsnCollectionToJson(
  SellerPortalAsnCollection instance,
) => <String, dynamic>{'seller_id': instance.sellerId, 'data': instance.data};
