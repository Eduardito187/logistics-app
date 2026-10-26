// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_goods_receipt_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordGoodsReceiptRequest _$RecordGoodsReceiptRequestFromJson(
  Map<String, dynamic> json,
) => RecordGoodsReceiptRequest(
  asnId: json['asn_id'] as String,
  lines: (json['lines'] as List<dynamic>)
      .map((e) => Lines2.fromJson(e as Map<String, dynamic>))
      .toList(),
  sellerSkuRef: json['seller_sku_ref'] as String?,
);

Map<String, dynamic> _$RecordGoodsReceiptRequestToJson(
  RecordGoodsReceiptRequest instance,
) => <String, dynamic>{
  'asn_id': instance.asnId,
  'seller_sku_ref': instance.sellerSkuRef,
  'lines': instance.lines,
};
