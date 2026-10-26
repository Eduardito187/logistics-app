// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SellerCollection _$SellerCollectionFromJson(Map<String, dynamic> json) =>
    SellerCollection(
      data: (json['data'] as List<dynamic>)
          .map((e) => Seller.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: json['meta'] == null
          ? null
          : PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SellerCollectionToJson(SellerCollection instance) =>
    <String, dynamic>{'data': instance.data, 'meta': instance.meta};
