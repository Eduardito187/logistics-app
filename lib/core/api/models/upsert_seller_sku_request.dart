// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'upsert_seller_sku_request.g.dart';

@JsonSerializable()
class UpsertSellerSkuRequest {
  const UpsertSellerSkuRequest({required this.sku, this.sapMaterial});

  factory UpsertSellerSkuRequest.fromJson(Map<String, Object?> json) =>
      _$UpsertSellerSkuRequestFromJson(json);

  final String sku;
  @JsonKey(name: 'sap_material')
  final String? sapMaterial;

  Map<String, Object?> toJson() => _$UpsertSellerSkuRequestToJson(this);
}
