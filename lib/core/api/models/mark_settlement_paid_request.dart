// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'mark_settlement_paid_request.g.dart';

@JsonSerializable()
class MarkSettlementPaidRequest {
  const MarkSettlementPaidRequest({required this.paymentReference});

  factory MarkSettlementPaidRequest.fromJson(Map<String, Object?> json) =>
      _$MarkSettlementPaidRequestFromJson(json);

  @JsonKey(name: 'payment_reference')
  final String paymentReference;

  Map<String, Object?> toJson() => _$MarkSettlementPaidRequestToJson(this);
}
