// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'seller_portal_settlement.dart';

part 'seller_portal_settlement_collection.g.dart';

@JsonSerializable()
class SellerPortalSettlementCollection {
  const SellerPortalSettlementCollection({
    required this.sellerId,
    required this.data,
  });

  factory SellerPortalSettlementCollection.fromJson(
    Map<String, Object?> json,
  ) => _$SellerPortalSettlementCollectionFromJson(json);

  @JsonKey(name: 'seller_id')
  final String sellerId;
  final List<SellerPortalSettlement> data;

  Map<String, Object?> toJson() =>
      _$SellerPortalSettlementCollectionToJson(this);
}
