// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'carrier_document.dart';
import 'corridor_type.dart';
import 'settlement_status.dart';

part 'settlement.g.dart';

@JsonSerializable()
class Settlement {
  const Settlement({
    required this.id,
    required this.carrierId,
    required this.corridorFrom,
    required this.corridorTo,
    required this.corridorType,
    required this.period,
    required this.amountCents,
    required this.currency,
    required this.reference,
    required this.status,
    required this.documents,
    this.carrierName,
    this.disputeReason,
    this.paymentReference,
  });

  factory Settlement.fromJson(Map<String, Object?> json) =>
      _$SettlementFromJson(json);

  final String id;
  @JsonKey(name: 'carrier_id')
  final String carrierId;

  /// Nombre legible del transportista (carriers.name); null si ya no existe
  @JsonKey(name: 'carrier_name')
  final String? carrierName;
  @JsonKey(name: 'corridor_from')
  final String corridorFrom;
  @JsonKey(name: 'corridor_to')
  final String corridorTo;
  @JsonKey(name: 'corridor_type')
  final CorridorType corridorType;
  final String period;
  @JsonKey(name: 'amount_cents')
  final int amountCents;
  final String currency;
  final String reference;
  final SettlementStatus status;
  @JsonKey(name: 'dispute_reason')
  final String? disputeReason;
  @JsonKey(name: 'payment_reference')
  final String? paymentReference;
  final List<CarrierDocument> documents;

  Map<String, Object?> toJson() => _$SettlementToJson(this);
}
