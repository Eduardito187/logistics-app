// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_settlement_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SellerSettlementCollection _$SellerSettlementCollectionFromJson(
  Map<String, dynamic> json,
) => SellerSettlementCollection(
  data: (json['data'] as List<dynamic>)
      .map((e) => SellerSettlement.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SellerSettlementCollectionToJson(
  SellerSettlementCollection instance,
) => <String, dynamic>{'data': instance.data};
