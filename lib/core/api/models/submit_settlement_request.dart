// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'carrier_document.dart';
import 'corridor_type.dart';

part 'submit_settlement_request.g.dart';

@JsonSerializable()
class SubmitSettlementRequest {
  const SubmitSettlementRequest({
    required this.corridorFrom,
    required this.corridorTo,
    required this.corridorType,
    required this.period,
    required this.amountCents,
    required this.currency,
    required this.reference,
    this.documents,
  });

  factory SubmitSettlementRequest.fromJson(Map<String, Object?> json) =>
      _$SubmitSettlementRequestFromJson(json);

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
  final List<CarrierDocument>? documents;

  Map<String, Object?> toJson() => _$SubmitSettlementRequestToJson(this);
}
