// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'fulfillment_mode.dart';

part 'stock_on_hand.g.dart';

@JsonSerializable()
class StockOnHand {
  const StockOnHand({
    required this.fulfillmentMode,
    required this.ownerPartyId,
    required this.available,
    required this.reserved,
    required this.onHand,
    required this.lots,
  });

  factory StockOnHand.fromJson(Map<String, Object?> json) =>
      _$StockOnHandFromJson(json);

  @JsonKey(name: 'fulfillment_mode')
  final FulfillmentMode fulfillmentMode;
  @JsonKey(name: 'owner_party_id')
  final String? ownerPartyId;
  final int available;
  final int reserved;
  @JsonKey(name: 'on_hand')
  final int onHand;

  /// Number of lots aggregated into this row.
  final int lots;

  Map<String, Object?> toJson() => _$StockOnHandToJson(this);
}
