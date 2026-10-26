// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'seller_settlement.dart';

part 'seller_settlement_collection.g.dart';

@JsonSerializable()
class SellerSettlementCollection {
  const SellerSettlementCollection({required this.data});

  factory SellerSettlementCollection.fromJson(Map<String, Object?> json) =>
      _$SellerSettlementCollectionFromJson(json);

  final List<SellerSettlement> data;

  Map<String, Object?> toJson() => _$SellerSettlementCollectionToJson(this);
}
