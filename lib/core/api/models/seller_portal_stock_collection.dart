// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'seller_portal_stock_lot.dart';

part 'seller_portal_stock_collection.g.dart';

@JsonSerializable()
class SellerPortalStockCollection {
  const SellerPortalStockCollection({
    required this.sellerId,
    required this.data,
  });

  factory SellerPortalStockCollection.fromJson(Map<String, Object?> json) =>
      _$SellerPortalStockCollectionFromJson(json);

  @JsonKey(name: 'seller_id')
  final String sellerId;
  final List<SellerPortalStockLot> data;

  Map<String, Object?> toJson() => _$SellerPortalStockCollectionToJson(this);
}
