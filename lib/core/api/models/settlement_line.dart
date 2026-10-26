// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'settlement_line.g.dart';

@JsonSerializable()
class SettlementLine {
  const SettlementLine({
    required this.shipmentId,
    required this.dispatchReference,
    required this.baseAmountCents,
    required this.currency,
  });

  factory SettlementLine.fromJson(Map<String, Object?> json) =>
      _$SettlementLineFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  @JsonKey(name: 'dispatch_reference')
  final String dispatchReference;
  @JsonKey(name: 'base_amount_cents')
  final int baseAmountCents;
  final String currency;

  Map<String, Object?> toJson() => _$SettlementLineToJson(this);
}
