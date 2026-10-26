// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'lines2.dart';

part 'record_goods_receipt_request.g.dart';

@JsonSerializable()
class RecordGoodsReceiptRequest {
  const RecordGoodsReceiptRequest({
    required this.asnId,
    required this.lines,
    this.sellerSkuRef,
  });

  factory RecordGoodsReceiptRequest.fromJson(Map<String, Object?> json) =>
      _$RecordGoodsReceiptRequestFromJson(json);

  @JsonKey(name: 'asn_id')
  final String asnId;
  @JsonKey(name: 'seller_sku_ref')
  final String? sellerSkuRef;
  final List<Lines2> lines;

  Map<String, Object?> toJson() => _$RecordGoodsReceiptRequestToJson(this);
}
