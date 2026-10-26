// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upsert_seller_sku_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpsertSellerSkuRequest _$UpsertSellerSkuRequestFromJson(
  Map<String, dynamic> json,
) => UpsertSellerSkuRequest(
  sku: json['sku'] as String,
  sapMaterial: json['sap_material'] as String?,
);

Map<String, dynamic> _$UpsertSellerSkuRequestToJson(
  UpsertSellerSkuRequest instance,
) => <String, dynamic>{
  'sku': instance.sku,
  'sap_material': instance.sapMaterial,
};
