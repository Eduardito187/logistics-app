// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'stock_on_hand.dart';

part 'stock_on_hand_collection.g.dart';

@JsonSerializable()
class StockOnHandCollection {
  const StockOnHandCollection({required this.data});

  factory StockOnHandCollection.fromJson(Map<String, Object?> json) =>
      _$StockOnHandCollectionFromJson(json);

  final List<StockOnHand> data;

  Map<String, Object?> toJson() => _$StockOnHandCollectionToJson(this);
}
